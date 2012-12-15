package Rex::WebUI::Dashboard;

use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub index {
   my $self = shift;

   #my $tasks = $self->rex->get_tasks;
   my $tasks = ['Update Stage Server', 'Update Stage Server','Update Web Cluster', 'Restart Nginx', 'Restart Database Server'];

   $self->stash(tasks => $tasks);

   $self->render;
}

sub view {
   my $self = shift;
   $self->render;
}

1;
