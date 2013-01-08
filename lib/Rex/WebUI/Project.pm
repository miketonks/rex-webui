package Rex::WebUI::Project;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

sub index {
   my $self = shift;

   my $id = $self->param("id");
   my $project = $self->config->{projects}->[$id];

	$self->rex->load_rexfile($project->{rexfile});

   my $tasks = $self->rex->get_tasks;
   #my $tasks = ['Update Stage Server', 'Update Stage Server','Update Web Cluster', 'Restart Nginx', 'Restart Database Server'];

   my $servers = $self->rex->get_servers;

   $self->stash(name => $project->{name});

   $self->stash(rexfile => $self->rex->{rexfile});
   $self->stash(tasks => $tasks);
   $self->stash(servers => $servers);

   $self->app->log->debug("xTASKS: " . Dumper($tasks));

   $self->render;

}


1;
