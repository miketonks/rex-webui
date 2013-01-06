package Rex::WebUI::Task;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# This action will render a template
sub view
{
	my $self = shift;

   my $id        = $self->param("id");
	my $task_name = $self->param("name");

   my $project = $self->config->{projects}->[$id];
	$self->rex->load_rexfile($project->{rexfile});

	$self->app->log->debug("Load task: $task_name");

	my $task = $self->rex->get_task($task_name);

	$self->stash(task => $task);

	$self->render;
}

# run a rex task in a conventional HTTP GET
sub run
{
	my $self = shift;

   my $id        = $self->param("id");
	my $task_name = $self->param("name");

   my $project = $self->config->{projects}->[$id];
	$self->rex->load_rexfile($project->{rexfile});

	$self->app->log->debug("Load task: $task_name");


	my $task = $self->rex->get_task($task_name);

	unless ($task) {

		$self->stash(task => "Not Found: $task");
		$self->render;
	}

	$self->stash(task => $task);

	my ($result, $log) = $self->rex->run_task($task_name);

	$self->stash(result => $result);
	$self->stash(log => $log);

	$self->render;
}

# just a test method to explore mojo streaming
#sub stream
#{
#    my $self = shift;
#
#	$self->render_later;
#
#    # Start recurring timer
#    my $i = 1;
#
#    my $iterations = 10;
#
#    my $id = Mojo::IOLoop->recurring(1 => sub {
#
#      warn "chuck $i";
#      $self->write_chunk("chunk $i\n", sub {} );
#      $self->finish if $i++ == $iterations;
#    });
#
#    # Stop recurring timer
#    $self->on(finish => sub { Mojo::IOLoop->remove($id) });
#};

# run a rex task in a websocket, sending back the log messages as we go
sub run_ws
{
	my $self = shift;

	Mojo::IOLoop->stream($self->tx->connection)->timeout(300);

	my $i = 0;
	my $log_position = 0;
	my $cb;

	my $rex_status :shared = 'init';
	my @log_messages :shared = ();

   my $id        = $self->param("id");
	my $task_name = $self->param("name");

   my $project = $self->config->{projects}->[$id];
	$self->rex->load_rexfile($project->{rexfile});

	$self->app->log->debug("Load task: $task_name");

	my $task = $self->rex->get_task($task_name);

	my $pid = "$self";

	warn "PID: $pid";

	my $temp_logfile     = "/tmp/rex_" . time . '.log';
	my $temp_status_file = "/tmp/rex_" . time . '.status';

	$self->res->headers->content_type('text/event-stream');

	$self->_set_status($temp_status_file, 'init');

	# after forking parent thread can write to websocket, but child can't
	if ($self->_fork_process()) {

		# parent thread
		$self->app->log->debug("Parent Thread - wait for end signal");

		$cb = sub {
			sleep 1;
			$i++;
			my $status = $self->_get_status($temp_status_file);

			my ($log_lines, $new_log_position) = $self->_read_log($temp_logfile, $log_position);

			$log_position = $new_log_position;

			foreach my $log_line (@$log_lines) {

#				warn "LOG: $log_line";
				$_[0]->send($log_line);
			}

			if ($status =~ /^done/) {
				$_[0]->send("STATUS: $status [$i]");
				unlink $temp_logfile;
				unlink $temp_status_file;
			} else
			{
				$_[0]->send("STATUS: $status [$i]", $cb);
			}
		};

		$self->$cb;

		return;
	}

	$self->app->log->debug("calling rex: $task_name");
	$self->tx->send( "calling rex: $task_name" );

	$rex_status = 'running';
	$self->_set_status($temp_status_file, 'running');

	my $result = $self->rex->run_task($task_name, $temp_logfile);

	$self->_set_status($temp_status_file, "done [$result]");

	warn "DONE [$result]";

	exit(0);
}

sub _fork_process
{
	my $self = shift;

	# Block signals whilst we fork the new child process
	$SIG{CHLD} = 'IGNORE';

	my $pid;

	# Fork the new child process
	if (!defined($pid = fork)) {

		$self->app->log->debug("Fork: $!");
		die("Fork: $!");
	}

	# Am I the parent or the child?
	if ($pid) {
		# Ensure we return to caller

		$self->app->log->debug("Child - return pid: $pid");

		return $pid;
	}

	# I am the child - as I can't return from here - make sure sig(INT) kills me
	$SIG{INT} = 'DEFAULT';

	$self->app->log->debug("Parent lives");

	return undef;
}

sub _set_status
{
	my ($self, $temp_status_file, $status) = @_;

	open FILE, ">", $temp_status_file;
	print FILE $status;
	close FILE;

	#warn "WROTE: $temp_status_file, $status";
}

sub _get_status
{
	my ($self, $temp_status_file) = @_;

	open FILE, "<", $temp_status_file;

	my @lines = <FILE>;

	my $status = $lines[0];

	#warn "READ: $temp_status_file, $status";

	return $status;
}

sub _read_log
{
	my ($self, $logfile, $log_position) = @_;

	my $log_lines = [];
	my $total_lines = 0;

	# this is a very, very crude way to tail the log, but it will do fine for small log files

	if (-e $logfile) {
		open FILE, "<", $logfile;

		my @lines = <FILE>;

		$total_lines = scalar @lines;

		if ($total_lines >= $log_position) {

			foreach my $i ($log_position .. $total_lines) {

				push @$log_lines, $lines[$i-1];
			}
		}
		$total_lines++;
	}

	return ($log_lines, $total_lines);
}

1;
