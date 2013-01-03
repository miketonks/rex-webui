
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

	$task =~ s/^$STEM//;
	
	my $tasklist = $self->get_tasklist;

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

sub get_servers
{
	my $self = shift;

	my $servers = [];

	my $tasks = $self->get_tasks;

	# build a list of server names from the task list
	foreach my $task (@$tasks) {

		$task = $self->get_task($task->{name});
		
		my $task_servers = $task->{server};
		
		next unless $task_servers && scalar @$task_servers > 0;
		
		foreach my $server (@$task_servers) {
			push @$servers, $server->{name} unless $server->{name} ~~ $servers;	
		}
	}	

	# expand server list into hashrefs, adding info from db if available
	# TODO: add db interface
	foreach my $server (@$servers) {
		
		$server = { name => $server};
	}
	
	return $servers;
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

	Rex::Logger::info("DONE");
	
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

