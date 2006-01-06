package VI::Chat::Eliza;
use strict;
use warnings;

use base 'VI::Chat';

use Chatbot::Eliza;
use LWP::Simple qw( get $ua );
use CGI::Util qw( escape );

$ua->agent('Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)');

sub init
{
    my ($self) = @_;
    $self->{bot} = Chatbot::Eliza->new( $self->config('eliza') );
}

sub random_reply
{
    my ( $self, $type ) = @_;
    my $bot = $self->{bot};
    $bot->{$type}->[ int &{ $bot->{myrand} }( scalar @{ $bot->{$type} } ) ];
}

{
    my @suffixes = ( q{}, qw( ... . ? ..? ) );

    sub lookup_reply
    {
        my ( $self, $what ) = @_;
        my $content;
        eval {
            local $SIG{ALRM} = sub { die "request timeout" };
            alarm 4;
            $content =
                get(  q{http://search.lycos.com/default.asp}
                    . q{?loc=searchbox&tab=web&adf=&query=}
                    . escape($what)
                    . q{&submit.x=0&submit.y=0&submit=Search} );
            alarm 0;
        };
        if ($@)
        {
            $self->log( error => $@ );
            return;
        }
        return if not defined $content;
        my @possibles;
        push @possibles, $1
            while ( $content =~ m{%26tab=web">([^<]+)</a></td>}g );
        my $reply = @possibles ? $possibles[ rand @possibles ] : return;
        return ucfirst( lc $reply ) . $suffixes[ rand @suffixes ];
    }
}

sub get_reply
{
    my ( $self, $who, $message ) = @_;
    my $bot   = $self->{bot};
    my $reply =
        ( not exists $self->{previous_reply} ) ? $self->random_reply('initial')
        : ( $bot->_testquit($_) ) ? $self->random_reply('final')
        : $message =~ /\Adebug memory\Z/i ? $bot->_debug_memory
        : $message =~ /\Adebug that\Z/i   ? $bot->debug_text()
        : $bot->transform($_);
    $reply = $self->lookup_reply($message)
        if defined $reply
        and $reply eq 'LOOKUP';
    $self->{previous_reply} = $reply;
}

1;

