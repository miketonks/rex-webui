package Rex::WebUI::Task;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# This action will render a template
sub view {
	my $self = shift;

	my $task_name = $self->param("name");

	$self->app->log->debug("Load task: $task_name");
	  
	my $task = $self->rex->get_task($task_name);

	$self->stash(task => $task);

	$self->render;
}

1;
