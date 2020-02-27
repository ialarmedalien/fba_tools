package Bio::KBase::Context;

use strict;
use warnings;

use Bio::KBase::utilities;
use Bio::KBase::Logger qw( get_logger );
use Bio::KBase::LocalCallContext;

=head1 Bio::KBase::Context

Handles creation and getting of LocalCallContext objects.

=cut

=head3 $context

Globally accessible context object; get it using Bio::KBase::Context::context()

=cut

my $context;

=head3 create_context

Create a LocalCallContext object for a token--user combination.

Args:
    hashref with keys

    token       # required; user token
    user_id     # required; user id

    user        # alternative legacy syntax for specifying user_id;
                # is converted to $lcc->user_id in the object

    method      # optional
    provenance  # optional

    setcontent  # whether or not to set the $context variable to this value

Returns:

$context, a Bio::KBase::LocalCallContext object containing this data

=cut

sub create_context {
    my ( $parameters ) = @_;

    $parameters->{ user_id } //= delete $parameters->{ user }
        if $parameters->{ user };

    $parameters = Bio::KBase::utilities::args(
        $parameters,
        [ "token", "user_id" ],
        {
            method     => "unknown",
            provenance => [],
            setcontext => 1
        }
    );

    my $local_context = Bio::KBase::LocalCallContext->new(
        $parameters->{ token },
        $parameters->{ user_id },
        $parameters->{ provenance },
        $parameters->{ method },
    );

    set_context( $local_context ) if $parameters->{ setcontext };

    return $local_context;

}

=head3 create_context_from_client_config

Create a LocalCallContext object from a client config file. Auth config info is
read from the supplied filename or $ENV{ KB_CLIENT_CONFIG }.

Args:

    hashref with keys

    filename    # config file with auth data (user id / token) in it. optional;
                # $ENV{ KB_CLIENT_CONFIG } or $ENV{ KB_DEPLOYMENT_CONFIG } may
                # also be supplied.

All optional; data used to create the LocalCallContext object:
    setcontext  # whether or not to use this data to set the current context
    method
    provenance

Returns:

LocalCallContext object

=cut

sub create_context_from_client_config {
    my ( $parameters ) = @_;
    $parameters = Bio::KBase::utilities::args(
        $parameters,
        [],
        {
            filename   => $ENV{ KB_CLIENT_CONFIG },
            setcontext => 1,
            method     => "unknown",
            provenance => []
        }
    );

    # if $ENV{ KB_CLIENT_CONFIG } is not defined, read_config will check
    # $ENV{ KB_DEPLOYMENT_CONFIG }; if that is not defined, it will bail.
    my $config = Bio::KBase::utilities::read_config( {
        filename => $parameters->{ filename },
        service  => "authentication",
    } );

    unless ( $config->{ authentication }{ token } ) {
        $config->{ authentication }{ token } =
            $ENV{ KB_AUTH_TOKEN } // $ENV{ KBASE_TEST_TOKEN };

        die 'Required parameter authentication token not found'
            unless $config->{ authentication }{ token };

        get_logger->info( 'setting auth token from environment variable' );

    }

    unless ( $config->{ authentication }{ user_id } ) {
        # TODO: this should be made non-user specific
        get_logger->info( 'setting user_id to default, chenry' );
        $config->{ authentication }{ user_id } //=
            $ENV{ KBASE_TEST_USER } // "chenry";
    }

    return create_context( {
        method     => $parameters->{ method },
        provenance => $parameters->{ provenance },
        setcontext => $parameters->{ setcontext },
        token      => $config->{ authentication }{ token },
        user_id    => $config->{ authentication }{ user_id },
    } );
}

=head3 set_context

Given a context object, sets the current $Bio::KBase::Context::context to it.
Can also be used to set the context to undef.

=cut

sub set_context {
    my ( $local_context ) = @_;
    get_logger()->info( message => {
        event   => 'set_context',
        context => $local_context,
    } );
    $context = $local_context;
}

sub context {
    return $context;
}

sub _get_context_property {
    my ( $property ) = @_;
    my $context = context() or die 'Bio::KBase::Context has not been initialized';
    return $context->$property;
}

sub token {
    return _get_context_property( 'token' );
}

sub method {
    return _get_context_property( 'method' );
}

sub provenance {
    return _get_context_property( 'provenance' );
}

sub user_id {
    return _get_context_property( 'user_id' );
}

1;