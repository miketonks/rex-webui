package Rex::WebUI::Project;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

sub index {

   my $self = shift;

   my $id = $self->param("id");
   my $project = $self->config->{projects}->[$id];

   if ($self->rex->load_rexfile($project->{rexfile})) {

	   my $tasks   = $self->rex->get_tasks;
	   my $servers = $self->rex->get_servers;

	   $self->stash(name => $project->{name});

	   $self->stash(rexfile => $self->rex->{rexfile});
	   $self->stash(tasks => $tasks);
	   $self->stash(servers => $servers);

	   $self->render;
   }
   else {

	   $self->stash(error => $self->rex->error_message);
	   $self->render(template => 'project/rexfile_error');
   }
}

1;
