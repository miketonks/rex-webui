package Rex::WebUI::Dashboard;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# This action will render a template
sub index {
   my $self = shift;

   $self->stash(name => $self->config->{name});

   $self->render;
}

sub view {
   my $self = shift;
   $self->render;
}

1;
