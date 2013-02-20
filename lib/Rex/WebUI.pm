
package Rex::WebUI;

use strict;

use Mojo::Base "Mojolicious";

use Mojo::Log;

use Rex::WebUI::Model::LogBook;
use Rex::WebUI::Model::RexInterface;

use DBIx::Foo qw(:all);
use Data::Dumper;

# This method will run once at server start
sub startup {
	my $self = shift;

	my @cfg = ("/etc/rex/webui.conf", "/usr/local/etc/rex/webui.conf", "webui.conf");
	my $cfg;
	for my $file (@cfg) {
		if(-f $file) {
			$cfg = $file;
			last;
		}
	}
	$self->plugin('Config', file => $cfg);

warn "start ********************************************************";

	if (my $secret = $self->config->{secret_passphrase}) {
		$self->secret($secret);
	}

	my $db_config = $self->config->{db_config} || [ dsn => 'dbi:SQLite:dbname=webui.db', username => '', password => '' ];

	$self->plugin('database', {
		@$db_config,
		helper		=> 'dbh',
	});

	$self->check_db_config($db_config);

	$self->helper(rex => sub { state $rex = Rex::WebUI::Model::RexInterface->new });
	$self->helper(logbook => sub { state $rex = Rex::WebUI::Model::LogBook->new($self->dbh) });

	#$self->rex->load_rexfile($self->config->{rexfile});

	# Router
	my $r = $self->routes;

	# Normal route to controller
	$r->get("/")->to("dashboard#index");
	$r->get("/dashboard")->to("dashboard#index");
	$r->get("/notification_message")->to("dashboard#notification_message");

	$r->get("/project/:id")->to("project#index");
	$r->get("/project/:id/task/view/:name")->to("task#view");
	$r->post("/project/:id/task/run/:name")->to("task#run");
	$r->websocket("/project/:id/task/tail_ws/:jobid")->to("task#tail_ws")->name('tail_ws');
}

sub check_db_config {
	my ($self, $db_config) = @_;

	my $check = $self->selectrow_array("select userid from users order by userid limit 1");

	if ($check) {
		warn "Database OK: $check";
		return 1;
	}
	elsif ($db_config->[1] =~ /^dbi:SQLite/) {
		return 	$self->_init_sqllite_db;
	}
	else {
		die "Database is not initialised - check your setup";
	}
}

sub _init_sqllite_db {
	my $self = shift;

	# This is a very simple SQLite database template to allow us to ship the app via cpan / github and have a ready to go data store.
	# Optionally the app can be configured to use MySQL etc.
	# Hopefully we can maintain compatibility by using standard sql syntax.
	# TODO: Create setup scripts for other db types

	warn "Setting up SQLite Database";

	$self->dbh_do("create table users (userid INTEGER PRIMARY KEY AUTOINCREMENT, username varchar(20))");
	$self->dbh_do("insert into users (userid, username) values (1, 'admin')");

	$self->dbh_do("create table status (statusid INTEGER PRIMARY KEY AUTOINCREMENT, status varchar(20))");
	$self->dbh_do("insert into status (statusid, status) values (0, 'Starting'), (1, 'Running'), (2, 'Completed'), (3, 'Died')");

	$self->dbh_do("create table logbook (jobid INTEGER PRIMARY KEY AUTOINCREMENT, userid int not null, task_name varchar(100), server varchar(100), statusid int, pid int)");
	return 1;
}

1;
