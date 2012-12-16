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

   $self->plugin('database', { 
      dsn      => 'dbi:SQLite:dbname=test.db',
      username => '',
      password => '',
      helper   => 'dbh',
   });

   if (my $secret = $self->config->{secret_passphrase}) {
	   $self->secret($secret);
   }

	my $test = $self->dbh->selectrow_hashref("select * from test");
	
	warn Dumper($test);
	
#   $self->plugin("Rex::IO::Mojolicious::Plugin::RexIOServer");

   $self->helper(rex => sub { state $rex = Rex::WebUI::Model::RexInterface->new });
   
   # Router
   my $r = $self->routes;

   # Normal route to controller
   $r->get("/")->to("dashboard#index");
   $r->get("/dashboard")->to("dashboard#view");
   $r->get("/task/:name")->to("task#view");
}

#sub rex {
#
#	my $rex_interface = Rex::WebUI::Model::RexInterface();
#	
#	return $rex_interface;	
#}

1;
