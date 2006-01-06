package VI::Wheel;
use strict;
use warnings;

use Carp;

sub run;

sub new {
    my ($class, $config, $handlers) = @_;
    my $self = bless { config => $config, handlers => $handlers }, $class;
    $self->init;
    $self;
}

sub init { }

sub config {
    my ($self, $key) = @_;
    $self->{config}->($key);
}

sub handle {
    my ($self, $name) = @_;
    my $handler = $self->{handlers}{$name};
    if ( defined $handler ) {
        return $handler;
    }
    elsif ( $handler eq 'log' ) {
        croak "handler required for 'log'";
    }
    else {
        return sub {};
    }
}

sub log {
    my ($self, @args) = @_;
    $self->handle('log')->(@args);
}

1;

