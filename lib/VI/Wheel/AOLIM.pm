package VI::Wheel::AOLIM;
use strict;
use warnings;

use base 'VI::Wheel';

use Net::OSCAR qw(:standard);
use Time::HiRes qw(sleep);
use HTML::Strip;

my $hs = HTML::Strip->new;

sub run
{
    my ($wheel) = @_;
    my $config = $wheel->config('aolim');
    my %requests;
    my $oscar = Net::OSCAR->new( capabilities => [qw( typing_status )] );

    $oscar->set_callback_im_in(
        sub {
            my ( $oscar, $sender, $raw_message, $is_away ) = @_;
            my $message = $hs->parse($raw_message);
            $hs->eof;
            chomp $message;
            $wheel->log( message_from => $sender, $message );
            my $reply = $wheel->handle('message')->( $sender, $message );
            return unless defined $reply;
            chomp $reply;

            sleep rand() * 10 + 2;
            $oscar->send_typing_status( $sender, TYPINGSTATUS_STARTED );
            sleep 0.1 * length($reply) + rand() * 0.5;
            $oscar->send_typing_status( $sender, TYPINGSTATUS_FINISHED );

            my $reqid = $oscar->send_im( $sender, $reply );
            $requests{$reqid} = defined $reply ? $reply : '[no reply]';
            $wheel->log( message_to => $sender, $reply );    # XXX
        }
    );

    $oscar->set_callback_im_ok(
        sub {
            my ( $oscar, $to, $reqid ) = @_;

            #            $wheel->log(message => "to $to: $requests{$reqid}");
            #            delete $requests{$reqid};
        }
    );

    $oscar->set_callback_signon_done(
        sub {
            my ($oscar) = @_;
            $wheel->log( aolim => 'signed in successfully' );
            $oscar->set_info('Domo arigato, Mr. Roboto!');
        }
    );

    $oscar->set_callback_evil(
        sub {
            my ( $oscar, $newevil, $from ) = @_;
            $from ||= 'ANONYMOUS';
            $wheel->log( aolim => "We've been EVILed from $from!" );
        }
    );

    $wheel->log( aolim => 'signing on' );
    $oscar->signon( $config->{username}, $config->{password} );
    $oscar->timeout(1);    # seconds

    local $SIG{INT} = sub {
        $wheel->log( aolim => 'signing off' );
        $oscar->signoff;
        sleep 1;
        exit;
    };

    $wheel->log( aolim => 'starting main loop' );
    while (1)
    {
        $oscar->do_one_loop;
        $wheel->handle('idle')->();
    }
}

1;

