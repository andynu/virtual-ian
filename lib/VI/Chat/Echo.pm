package VI::Chat::Echo;
use strict;
use warnings;

use base 'VI::Chat';

sub get_reply
{
    my ($self, $who, $message) = @_;
    "$who said, '$message'!";
}

1;

