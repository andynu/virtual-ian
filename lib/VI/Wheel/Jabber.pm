package VI::Wheel::Jabber;
use strict;
use warnings;

use base 'VI::Wheel';

use Net::Jabber;
use Time::HiRes qw(sleep);

sub run
{
    my ($wheel) = @_;
    my $config = $wheel->config('jabber');
    my $connection = Net::Jabber::Client->new( debuglevel => 0 );

    $connection->SetCallBacks(
        message => sub {
            my ( $sid, $message ) = @_;
            my $type     = $message->GetType();
            my $fromJID  = $message->GetFrom("jid");
            my $from     = $fromJID->GetUserID();
            my $resource = $fromJID->GetResource();
            my $subject  = $message->GetSubject();
            my $body     = $message->GetBody();

            my $sender = "$from/$resource";    # good enough UID
            $wheel->log( message_from => $sender, $body );
            my $reply_text = $wheel->handle('message')->( $sender, $body );
            chomp $reply_text;

            #sleep 0.2 * length($reply_text);

            $wheel->log( message_to => $sender, $reply_text );
            my $reply = $message->Reply( body => $reply_text );
            $connection->SendWithID($reply);

        },
        onauth => sub {
            $wheel->log( jabber => 'fetching roster' );
            $connection->RosterGet();

            $wheel->log( jabber => 'notifying world of our our presence' );
            $connection->PresenceSend();
        },
        onprocess => sub {
            $wheel->handle('idle')->();
        },
        onexit => sub {
            $wheel->log( jabber => 'exiting' );
        },
    );

    local $SIG{INT} = sub {
        $wheel->log( jabber => 'signing off' );
        $connection->Disconnect;
        sleep 1;
        exit;
    };

    $wheel->log( jabber => 'starting main loop' );
    $connection->Execute( %$config, processtimeout => 1, );
}

1;

