#!/usr/bin/perl

use strict;

use Test::More tests => 6;

use Rex -base;
#use Rex::TaskList;

my $rexfile = 'SampleRexfile';

ok(-e $rexfile, "SampleRexfile found");

do($rexfile);

my $tasklist = Rex::TaskList->create();

my $tasks = [ $tasklist->get_tasks ];

#unless(@tasks) {
#   print "   no tasks defined.\n";
#   exit;
#}

is(scalar @$tasks, 2, "2 Tasks defined");

my $task1 = $tasks->[0];
my $task2 = $tasks->[1];

is($task1, 'uname', "First task is: uname");
is($task2, 'uptime', "Second task is: uptime");

is($tasklist->get_desc($task1), 'Show Unix version', 'Task 1 desc');
is($tasklist->get_desc($task2), 'Show Uptime', 'Task 2 desc');

#for my $task (@tasks) {
#   printf "  %-30s %s\n", $task, Rex::TaskList->create()->get_desc($task);
#   if($opts{'v'}) {
#       _print_color("      Servers: " . join(", ", @{ Rex::TaskList->create()->get_task($task)->{'server'} }) . "\n");
#   }
#}
