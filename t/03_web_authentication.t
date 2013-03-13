
use Test::More tests => 5;
use Test::Mojo;
use File::Copy;

use Rex::WebUI;

$Rex::WebUI::TEST_CONFIG_OPTIONS = {enable_authentication => 1};

# crude attempt to move any working db file out of the way
# but be warned, running developer tests may whack your local db!
my $db_file = "webui.db";
my $db_file_backup = "$db_file.xxx_temp";

move($db_file, $db_file_backup) if -f $db_file;

# Allow 302 redirect responses
my $t = Test::Mojo->new('Rex::WebUI');
$t->ua->max_redirects(1);


# Test if the HTML login form exists
$t->get_ok('/dashboard');
$t->status_is(200);
$t->text_is("#content_area h1" => "Login");

$t->post_ok('/project/0/task/run/uptime' => form => { username => 'admin', password => 'admin' });
$t->status_is(200);


move($db_file_backup, $db_file) if -f $db_file_backup;


