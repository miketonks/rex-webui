package Rex::WebUI::Admin;

use Mojo::Base 'Mojolicious::Controller';

use DBIx::Foo qw(:all);

use Data::Dumper;
use Digest::MD5  qw(md5_hex);

sub index {

	my $self = shift;

	die "Missing Admin Permissions" unless $self->current_user->{admin};

	my $users = $self->_get_users;

	$self->stash(users => $users);

	$self->render;
}

sub user
{
	my $self = shift;

	my $userid = $self->param("userid");
	my $user;

	if ($userid ~~ 'new') {
		$user = {};
	}
	else {
		$user = $self->_load_user($userid);
	}

	$self->stash(user => $user);
	$self->stash(admin => $self->current_user->{admin});

	$self->render('user');
}

sub user_process
{
	my $self = shift;

	my $validator = $self->create_validator;
	$validator->field('userid')->required(1)->regexp(qr/^new|\d+$/);
	$validator->field('username')->required(1)->length(3, 20);
	$validator->field('fullname')->required(0)->length(3, 60);
	$validator->field('admin')->required(0)->in(0, 1);
	$validator->field([qw/password confirm_password/])->each(sub { shift->required(0) });
	$validator->group('confirm_password' => [qw/password confirm_password/])->equal;
	$validator->when('userid')->regexp(qr/^new$/)->then(sub {
		my $validator = shift;
		$validator->field('password')->required(1)->length(5, 20);
		$validator->field('confirm_password')->required(1)->length(5, 20);
	});

#warn "MESSAGES: " . Dumper($validator->{messages});

	$validator->field('confirm_password')->messages(EQUAL_CONSTRAINT_FAILED => 'Passwords Do Not Match');

#warn "MESSAGES2: " . Dumper($validator->{messages});

	unless ($self->validate($validator)) {

		$self->render(json => { status => 'error', errors => $validator->errors });
		return;
	}

	die "Missing Admin Permissions" unless $self->current_user->{admin} || ($validator->values->{userid} ~~ $self->current_user->{userid});

	my $userid = $self->_save_user($validator->values);

	$self->render(json => { status => 'ok', userid => $userid, next => '/admin' });
}

sub _get_users
{
	my $self = shift;

	my $users = $self->selectall("select * from users");

	return $users;
}

sub _load_user
{
	my ($self, $userid) = @_;

	die "Invalid userid" unless $userid =~ /^\d+$/;

	my $user = $self->selectrow("select * from users where userid = ?", $userid);

	return $user;
}

sub _save_user
{
	my ($self, $data) = @_;

	$data->{admin} = $self->current_user->{admin} && $data->{admin} ? 1 : 0;

	my $query = $self->update_query('users');

	foreach my $field(qw/username fullname admin/) {

		$query->addField($field, $data->{$field});
	}

	$query->addField('password', md5_hex($data->{password})) if $data->{password}; # only set password if present

	my $userid;

	if ($data->{userid} ~~ 'new') {

		$userid = $query->DoInsert();

		$self->debug("Inserted user $data->{username} with userid: $userid");
	}
	else {

		$userid = $data->{userid};

		$query->addKey("userid", $userid);
		$query->DoUpdate();

		$self->debug("Updateded user $data->{username} with userid: $userid");
	}

	return $userid;
}

1;
