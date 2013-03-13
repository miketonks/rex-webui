
package Rex::WebUI;

use strict;

use Mojo::Base "Mojolicious";

use Mojo::Log;
use Mojolicious::Plugin::Authentication;
use Mojolicious::Plugin::Database;
use Mojolicious::Plugin::Validator;

use Rex::WebUI::Model::LogBook;
use Rex::WebUI::Model::RexInterface;

use Cwd qw(abs_path);

use DBIx::Foo qw(:all);
use Data::Dumper;
use Digest::MD5  qw(md5_hex);

use File::Basename 'dirname';
use File::Copy;
use File::Spec::Functions 'catdir';

our $VERSION = '0.01';

our $TEST_CONFIG_OPTIONS; # set to a hashref to pass in extra options for testing

# This method will run once at server start
sub startup {
	my $self = shift;

	$self->helper(debug => sub { shift->app->log->debug(@_) });

	$self->debug("Starting Up");

    # Switch to installable home directory
    $self->home->parse(catdir(dirname(__FILE__), 'WebUI'));
    $self->static->paths->[0] = $self->home->rel_dir('public');
    $self->renderer->paths->[0] = $self->home->rel_dir('templates');

	if (my $cfg = $self->_locate_config_file) {
		$self->plugin('Config', file => "$cfg");
	} else {
		# config should always be found because we ship a default config file, but best to check
		die "Config file not found" unless $cfg;
	}

	$self->config(%$TEST_CONFIG_OPTIONS) if $TEST_CONFIG_OPTIONS;

	if (my $secret = $self->config->{secret_passphrase}) {
		$self->secret($secret);
	}

	$self->set_db_config;

	$self->helper(rex => sub { state $rex = Rex::WebUI::Model::RexInterface->new });
	$self->helper(logbook => sub { state $rex = Rex::WebUI::Model::LogBook->new($self->dbh) });

    $self->plugin('validator', messages => {EQUAL_CONSTRAINT_FAILED => 'Passwords Do Not Match'});

    $self->plugin('authentication' => {
        'autoload_user' => 1,
        'session_key' => 'wickedapp',
        'load_user' => sub { return _load_user(@_); },
        'validate_user' => sub { return _validate_user(@_); },
    });

	# Router
	my $r = $self->routes;

	# Normal route to controller
	$r->get("/login")->to("login#login");
	$r->get("/logout")->to("login#logout_handler");
	$r->post("/login_process")->to("login#login_process");

	my $s = $r->bridge('/')->to('login#check');

	# Routes to secure pages (login required)
	$s->get("")->to("dashboard#index");
	$s->get("dashboard")->to("dashboard#index");
	$s->get("notification_message")->to("dashboard#notification_message");

	$s->get("/project/:id")->to("project#index");
	$s->get("/project/:id/task/view/:name")->to("task#view");
	$s->post("/project/:id/task/run/:name")->to("task#run");
	$s->websocket("/project/:id/task/tail_ws/:jobid")->to("task#tail_ws")->name('tail_ws');

	$s->get("/admin")->to("admin#index");
	$s->get("/admin/user/:userid")->to("admin#user");
	$s->post("/admin/user_process")->to("admin#user_process");
}

sub set_db_config
{
	my $self = shift;

	my $db_config = $self->config->{db_config} || [ dsn => 'dbi:SQLite:dbname=webui.db', username => '', password => '' ];

	if ($db_config->[1] =~ /^dbi:mysql/) {

		my $hash_config = { @$db_config };
		$hash_config->{options}->{mysql_auto_reconnect} = 1;
		$db_config = [ %$hash_config ];
	}

	$self->plugin('database', {
		@$db_config,
		helper		=> 'dbh',
	});

	$self->check_db_config($db_config);
}

sub check_db_config {
	my ($self, $db_config) = @_;
	my $check = $self->dbh->tables(undef, undef, 'users');

	if ($check) {
		#$self->debug("Database OK: $check");
		return 1;
	}
	elsif ($db_config->[1] =~ /^dbi:SQLite/i) {
		return 	$self->_init_sqllite_db;
	}
	else {
		die "Database is not initialised - check your setup";
	}
}

sub _locate_config_file
{
	my $self = shift;

	# check optional locations for config file, inc current directory
	my @cfg = ("/etc/rex/webui.conf", "/usr/local/etc/rex/webui.conf", abs_path("webui.conf"));

	my $cfg;
	for my $file (@cfg) {
		if(-f $file) {
			return $file;
			last;
		}
	}

	# finally if no config file is found, copy the template and the SampleRexfile from the mojo home dir
	foreach my $file (qw(webui.conf SampleRexfile)) {
		copy(abs_path($self->home->rel_file($file)), abs_path($file)) or die "No config file found, and unable to copy $file to current directory";
	}

	return abs_path("webui.conf");
}

sub _load_user
{
	my ($self, $userid) = @_;

	return undef unless $userid;

	$self->app->log->debug("Load User: $userid");

	my $user = $self->app->selectrow("select * from users where userid = ?", $userid);

	return $user;
}

sub _validate_user
{
	my ($self, $username, $password) = @_;

	# always allow access if authentication is not enabled
	return 1 unless $self->config->{enable_authentication};

	# require username and password
	return 0 unless $username && $password;

	# admin pass from config file takes priority, then accounts from db
	if ($username eq 'admin' && $self->config->{admin_password} && $password eq $self->config->{admin_password}) {

		$self->app->log->debug("User admin logged in with admin password from config file");
		return 1;
	}
	elsif (my $uid = $self->selectrow_array("select userid from users where username = ? and password = ?", $username, md5_hex($password))) {

		$self->app->log->debug("User $username logged in with username and password from db");
		return $uid;
	}
	else {

		$self->app->log->debug("Login failed for user $username");
		return 0;
	}
}


sub _init_sqllite_db {
	my $self = shift;

	# This is a very simple SQLite database template to allow us to ship the app via cpan / github and have a ready to go data store.
	# Optionally the app can be configured to use MySQL etc.
	# Hopefully we can maintain compatibility by using standard sql syntax.
	# TODO: Create setup scripts for other db types

	$self->debug("Setting up SQLite Database");

	$self->dbh_do("create table users (userid INTEGER PRIMARY KEY AUTOINCREMENT, username VARCHAR(20), fullname VARCHAR(50), password VARCHAR(32), admin INTEGER DEFAULT 0)");
	$self->dbh_do("insert into users (userid, username, fullname, password, admin) values (1, 'admin', 'Administrator', ?, 1)", md5_hex('admin'));

	$self->dbh_do("create table status (statusid INTEGER PRIMARY KEY AUTOINCREMENT, status VARCHAR(20))");
	$self->dbh_do("insert into status (statusid, status) values (0, 'Starting')");
	$self->dbh_do("insert into status (statusid, status) values (1, 'Running')");
	$self->dbh_do("insert into status (statusid, status) values (2, 'Completed')");
	$self->dbh_do("insert into status (statusid, status) values (3, 'Died')");

	$self->dbh_do("create table logbook (jobid INTEGER PRIMARY KEY AUTOINCREMENT, userid INTEGER NOT NULL, task_name VARCHAR(100), server VARCHAR(100), statusid INTEGER, pid INTEGER)");
	return 1;
}

1;


__END__

=head1 NAME

Rex::WebUI - Simple web frontend for rex (Remote Execution), using Mojolicious.  Easily deploy or manage servers via a web interface.

=head1 SYNOPSIS

  rex-webui daemon

  # or if you prefer using hypnotoad
  hypnotoad bin/rex-webui

and point your browser at http://localhost:3000

=head1 DESCRIPTION

This is an installable web application that provides a front end to Rex projects (see http://rexify.org)

Almost unlimited functionality is available via Rex, perfect for deploying servers and managing clusters, or anything you can automate via ssh.

Build multiple Rexfiles (one per project) and register them in webui.conf

The web interface allows to you browse and run tasks, and records a history of running and completed tasks.

A small SQLite db is used to store the history.


=head1 EXAMPLE CONFIG

  {
     name 				=> 'Rex Web Delopyment Console',
     secret_passphrase 	=> 'rex-webui',
     projects 				=> [
        {
           name        => 'SampleRexfile',
           rexfile     => "SampleRexfile",
           description => "This is a sample Project. With a few tasks.",
        },
     ],
     db_config 			=> [ dsn => 'dbi:SQLite:dbname=webui.db', username => '', password => '' ],
  };

=head1 SampleRexfile

 # Sample Rexfile

  desc "Show Unix version";
  task uname => sub {
      my $uname = run "uname -a";

      Rex::Logger::info("uname: $uname");

      return $uname;
  };

  desc "Show Uptime";
  task uptime => sub {
      my $uptime = run "uptime";

      Rex::Logger::info("uptime: $uptime");

      return $uptime;
  };

=cut
