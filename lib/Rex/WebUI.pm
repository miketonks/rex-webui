package Rex::WebUI;

use Mojo::Base "Mojolicious";

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

#   $self->plugin("Rex::IO::Mojolicious::Plugin::RexIOServer");

   # Router
   my $r = $self->routes;

   # Normal route to controller
   $r->get("/")->to("dashboard#index");
   $r->get("/dashboard")->to("dashboard#view");
}

1;
