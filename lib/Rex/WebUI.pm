package Rex::WebUI;

use Mojo::Base "Mojolicious";

use Mojo::Log;

use Rex::WebUI::Model::RexInterface;

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

	if (my $secret = $self->config->{secret_passphrase}) {
		$self->secret($secret);
	}

	$self->plugin('database', {
		dsn			=> 'dbi:SQLite:dbname=test.db',
		username 	=> '',
		password 	=> '',
		helper		=> 'dbh',
	});

	my $test = $self->dbh->selectrow_hashref("select * from test");

	warn Dumper($test);

#	$self->plugin("Rex::IO::Mojolicious::Plugin::RexIOServer");

	$self->helper(rex => sub { state $rex = Rex::WebUI::Model::RexInterface->new });

	#$self->rex->load_rexfile($self->config->{rexfile});

	# Router
	my $r = $self->routes;

	# Normal route to controller
	$r->get("/")->to("dashboard#index");
	$r->get("/dashboard")->to("dashboard#view");
#	$r->get("/task/view/:name")->to("task#view");
#	$r->get("/task/run/:name")->to("task#run");
#	$r->get("/task/stream/:id")->to("task#stream");
#	$r->websocket("/task/run_ws/:name")->to("task#run_ws");

   $r->get("/project/:id")->to("project#index");
   $r->get("/project/:id/task/view/:name")->to("task#view");
   $r->get("/project/:id/task/run/:name")->to("task#run");
   $r->websocket("/project/:id/task/run_ws/:name")->to("task#run_ws");
}

#sub rex {
#
#	my $rex_interface = Rex::WebUI::Model::RexInterface();
#
#	return $rex_interface;
#}

1;
