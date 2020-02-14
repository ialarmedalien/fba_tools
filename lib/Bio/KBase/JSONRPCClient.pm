package Bio::KBase::JSONRPCClient;
use strict;
use warnings;
use base 'JSON::RPC::Client';
use POSIX;
use Carp qw( croak );
use Ref::Util qw( is_hashref );

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ( $self, $uri, $headers, $obj ) = @_;

    my $result;

    if ( $uri =~ /\?/ ) {
        $result = $self->_get( $uri );
    }
    else {
        croak "object is not a hashref; it is a " . ( ref( $obj ) || 'SCALAR' )
            unless is_hashref $obj;
        $result = $self->_post( $uri, $headers, $obj );
    }

    my $service = $obj->{ method } =~ /^system\./ if ( $obj );

    $self->status_line( $result->status_line );

    if ( $result->is_success ) {

        return unless $result->content; # notification?

        return JSON::RPC::ServiceObject->new( $result, $self->json ) if $service;
    }

    return JSON::RPC::ReturnObject->new( $result, $self->json )
        if $result->content_type eq 'application/json';

    return;

}


sub _post {
    my ( $self, $uri, $headers, $obj ) = @_;
    my $json = $self->json;

    $obj->{ version } ||= $self->{ version } || '1.1';

    if ( $obj->{ version } eq '1.0') {
        delete $obj->{ version };
        if ( exists $obj->{ id } ) {
            $self->id( $obj->{ id } ) if $obj->{ id }; # if undef, it is notification.
        }
        else {
            $obj->{ id } = $self->id || ( $self->id( 'JSON::RPC::Client' ) );
        }
    }
    else {
        # Assign a random number to the id if one hasn't been set
        $obj->{ id } = $self->id // substr( rand(), 2 );
    }

    my $content = $json->encode( $obj );

    $self->ua->post(
        $uri,
        Content_Type   => $self->{ content_type },
        Content        => $content,
        Accept         => 'application/json',
        @$headers,
        ( $self->{token} ? ( Authorization => $self->{token} ) : () ),
    );
}

1;