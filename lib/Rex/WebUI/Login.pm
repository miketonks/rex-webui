package Rex::WebUI::Login;

use Mojo::Base 'Mojolicious::Controller';

use DBIx::Foo qw(:all);

use Data::Dumper;

sub login {

	my $self = shift;

	if ($self->config->{enable_authentication}) {

		$self->render;
	}
	else {

		return $self->redirect_to('/dashboard');
	}
}

sub login_process
{
	my $self = shift;

warn ">>>>>>>>>>>>>> login_process";

	my $validator = $self->create_validator;
	$validator->field('username')->required(1)->length(3, 20);
	$validator->field('password')->required(0)->length(3, 60);

	unless ($self->validate($validator)) {

		$self->render(json => { status => 'error', errors => $validator->errors });
		return;
	}

	my $params = $validator->values;

    if ($self->authenticate($params->{username}, $params->{password})) {

		$self->redirect_to('/dashboard');
		return 0;
	}
	else {
		$self->redirect_to('/login');
		return 0;
	}
}

sub check {
	my $self = shift;

	unless ($self->config->{enable_authentication}) {

		$self->authenticate unless $self->is_user_authenticated; # log in automatically (as admin)
		return 1;
	}
	else {

	}

	if ($self->is_user_authenticated) {
		return 1;
	}
	else {
		$self->app->log->debug("Not authenticated - redirecting to login page");
		$self->redirect_to('/login');
		return 0;
	}
};

sub logout_handler # renamed to avoid name conflict (causes infinite loop)
{
	my $self = shift;
warn "Logout **************************";

	$self->logout();
	return $self->redirect_to('/login');
}

1;
