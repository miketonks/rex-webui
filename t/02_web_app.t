
use Test::More tests => 3;
use Test::Mojo;

# Allow 302 redirect responses
my $t = Test::Mojo->new('Rex::WebUI');
#$t->ua->max_redirects(1);

# Test if the HTML login form exists
$t->get_ok('/dashboard');

$t->status_is(200);
$t->text_is("#content_area h1" => "Rex Web Delopyment Console - Dashboard");

#warn "CONTENT: " . $t->tx->res->body;