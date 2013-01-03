package Rex::WebUI::Dashboard;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# This action will render a template
sub index {
   my $self = shift;

   my $tasks = $self->rex->get_tasks;
   #my $tasks = ['Update Stage Server', 'Update Stage Server','Update Web Cluster', 'Restart Nginx', 'Restart Database Server'];

   my $servers = $self->rex->get_servers;

   $self->stash(name => $self->config->{name});

   $self->stash(rexfile => $self->rex->{rexfile});
   $self->stash(tasks => $tasks);
   $self->stash(servers => $servers);

   $self->app->log->debug("xTASKS: " . Dumper($tasks));

   $self->render;
}

sub view {
   my $self = shift;
   $self->render;
}

1;
