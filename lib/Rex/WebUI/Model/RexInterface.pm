
package Rex::WebUI::Model::RexInterface;

use strict;

use Rex -base;

use Rex::Batch;
use Rex::Group;

use Data::Dumper;

# rex task names end with with the module namespace as a 'stem' - remove for readability
my $STEM = 'WebUI:Model:RexInterface';

# global callback used to override / hook into Rex::Logger class
our $LOG_CALLBACK;


sub new { bless {}, shift }

sub get_task
{
	my ($self, $task) = @_;

	my $tasklist = $self->get_tasklist;

warn "TASKLIST: " . Dumper($tasklist);

	if ($tasklist->is_task("$STEM:$task")) {

		$task = {
			%{$tasklist->get_task("$STEM:$task")->get_data},
			name 		=> $task,
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

		$self->load_rexfile;

		my $tasklist = Rex::TaskList->create();

		return $self->{tasklist} = $tasklist;
	}
}

sub load_rexfile
{
	my ($self, $rexfile) = @_;

  	$rexfile = $self->{rexfile} || "SampleRexfile" unless $rexfile;

	if (defined do($rexfile)) {

		warn "Loaded Rexfile: $rexfile";

		$self->{rexfile} = $rexfile;
	}
	else {

		warn "Error loading Rexfile: $rexfile - $@";

		$self->{rexfile} = undef;
	}
}

sub run_task
{
	my ($self, $task, $temp_logfile) = @_;

	$::QUIET = 1;

	Rex::Config->set_log_filename($temp_logfile) if $temp_logfile;

	my $result = do_task("$STEM:$task");

	return $result;
}

sub register_log_callback
{
	my ($self, $callback) = @_;

	$LOG_CALLBACK = $callback;
}

sub release_log_callback
{
	my ($self) = shift;

	$LOG_CALLBACK = undef;
}


#sub Rex::Logger::info
#{
#	my ($msg, $type) = @_;
#
#	return unless $LOG_CALLBACK;
#
#	warn "XXX INFO: $msg";
#
#	if(defined($type)) {
#		$msg = Rex::Logger::format_string($msg, uc($type));
#	}
#	else {
#		$msg = Rex::Logger::format_string($msg, "INFO");
#	}
#
#	$LOG_CALLBACK->($msg);
#}
#
#sub Rex::Logger::debug
#{
#	my ($msg, $type) = @_;
#
#	return unless $LOG_CALLBACK;
#
#	warn "XXX DEBUG: $msg";
#
#	$msg = Rex::Logger::format_string($msg, "DEBUG");
#	$LOG_CALLBACK->($msg);
#}


1;

