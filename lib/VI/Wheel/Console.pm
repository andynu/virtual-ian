package VI::Wheel::Console;
use strict;
use warnings;

use base 'VI::Wheel';
use Time::HiRes qw(sleep);

sub run
{
    my ($self) = @_;
    $self->log( console => 'starting... enter lines of text' );

    while (<>)
    {
        chomp;
        $self->log( message_to => 'console', $_ );
        my $reply = $self->handle('message')->( $ENV{USER}, $_ );
        return unless defined $reply;
        chomp $reply;

        $self->log( console => 'sleeping' );
        sleep rand() * 10 + 2;
        $self->log( console => 'would send is-typing signal' );
        #$oscar->send_typing_status( $sender, TYPINGSTATUS_STARTED );
        sleep 0.1 * length($reply) + rand() * 0.5;
        #$oscar->send_typing_status( $sender, TYPINGSTATUS_FINISHED );
        $self->log( message_from => 'console', $reply );

        $self->handle('idle')->();
    }

    $self->log( console => 'done' );
}

1;

