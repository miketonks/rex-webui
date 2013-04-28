
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
$t->text_is("#content_area h1" => "Login", "Login form displayed");

$t->post_ok('/login_process' => form => { username => 'admin', password => 'admin' });
$t->status_is(200);
$t->text_is("#content_area h1" => "Rex Web Delopyment Console - Dashboard", "Dashboard Displayed");

$t->get_ok('/admin?nolayout=1');
$t->text_is("h1" => "Admin", "Admin screen Displayed");
$t->text_is("a#add_user" => "Add User Account", "Add User link Displayed");

$t->get_ok('/admin/user/new?nolayout=1');
$t->text_is("h2" => "Create New User Account", "Create User screen Displayed");

$t->post_ok('/admin/user_process' => form => { userid=> 'new', username => 'test', fullname => 'Test User', password => 'test99', confirm_password => 'test99' });
$t->json_is('/status' => 'ok');
$t->json_is('/userid' => 2);

move($db_file_backup, $db_file) if -f $db_file_backup;


