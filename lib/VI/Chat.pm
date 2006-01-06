package VI::Chat;
use strict;
use warnings;

use Carp;

sub get_reply;

sub new
{
    my ( $class, $config, $logger ) = @_;
    my $self = bless { config => $config, logger => $logger }, $class;
    $self->init;
    $self;
}

sub init { }

sub config
{
    my ( $self, $key ) = @_;
    $self->{config}->($key);
}

sub log {
    my ( $self, @args ) = @_;
    $self->{logger}->(@args);
}

1;

