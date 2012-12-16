
package Rex::WebUI::Model::RexInterface;

use strict;

use Rex -base;

use Data::Dumper;

my $STEM = 'WebUI:Model:RexInterface';

sub new { bless {}, shift }

sub get_task
{
	my ($self, $task) = @_;

	my $tasklist = $self->get_tasklist;

warn "TASKLIST: " . Dumper($tasklist);

	if ($tasklist->is_task("$STEM:$task")) {	

		$task = {
			name 		=> $task,
			desc 		=> $tasklist->get_desc("$STEM:$task"),
		};
		
		return $task;
	}
	else {
		
		warn "task '$task' not found";
		
		return undef;	
	}
}

sub get_tasks
{
	my $self = shift;

warn "COUNTER: " . $self->{counter}++;

warn "PACKAGE: " . __PACKAGE__;

	my $tasks;		

	if ($tasks = $self->{tasks}) {
		
		$self->log->debug("Tasks already loaded");;
	}
	else {
		
		my $tasklist = $self->get_tasklist;
		
		$tasks = [ $tasklist->get_tasks ];

		# get the task details for each
		foreach my $task (@$tasks) {

			$task =~ s/$STEM://;

			$task = {
				name 		=> $task,
				desc 		=> $tasklist->get_desc("$STEM:$task"),
			};
		}
	}
	
	return $tasks;
}

sub get_tasklist
{
	my $self = shift;

	if (my $tasklist = $self->{tasklist}) {
		
		return $tasklist;
	}
	else {

		$self->_load_rexfile;

		my $tasklist = Rex::TaskList->create();

		return $self->{tasklist} = $tasklist;
	}
}

sub _load_rexfile
{
	my $self = shift;
		
  	my $rexfile = "SampleRexfile";

	if (defined do($rexfile)) {
		
		warn "Loaded Rexfile: $rexfile";
		
		$self->{rexfile} = $rexfile;
	}
	else {
		
		warn "Error loading Rexfile: $rexfile - $@";	

		$self->{rexfile} = undef;
	}	
}

1;

