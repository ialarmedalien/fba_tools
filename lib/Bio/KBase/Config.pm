package Bio::KBase::Config;

use strict;
use warnings;

use Bio::KBase::utilities qw( args );

=head3 read_config

a general method for reading in service configurations and setting mandatory/optional values

Args: $hashref with keys

    filename    => '/path/to/config/file',
    service     => 'name_of_service',

Returns:
    $hashref with configuration data

    dies if service or filename are not specified or there is a problem
    with the config file

=cut

my $config;

sub read_config {
    my ( $args ) = @_;
    $args = Bio::KBase::utilities::args(
        $args,
        [],
        {
            filename  => $ENV{ KB_DEPLOYMENT_CONFIG },
            service   => $ENV{ KB_SERVICE_NAME },
            mandatory => [],
            optional  => {},
        }
    );

    my $service     = $args->{ service }  or error( "No service specified!" );
    my $config_file = $args->{ filename } or error( "No config file specified!" );

    error( "Specified config file " . $args->{ filename } . " doesn't exist!" )
        unless -e $config_file;

    my $c     = Config::Simple->new();
    $c->read( $args->{ filename } );
    my $hash  = $c->vars();
    for my $key ( keys %$hash ) {
        my @array = split /\./, $key, 2;
        $config->{ $array[ 0 ] }{ $array[ 1 ] } = $hash->{ $key };
    }

    $config->{ $service } = Bio::KBase::utilities::args(
        $config->{ $service },
        $args->{ mandatory },
        $args->{ optional }
    );

    $config->{ UtilConfig } = Bio::KBase::utilities::args(
        $config->{ UtilConfig },
        [],
        {
            fulltrace     => 0,
            reportimpl    => 0,
            call_back_url => $ENV{ SDK_CALLBACK_URL },
            token         => undef
        }
    );

    warn 'config: ' . Dumper $config;

    return $config;
}

=head3 config_hash

Return the full config data structure

Note that mutating this structure in a function will mutate the original!

=cut

sub config_hash {
    return $config;
}

=head3 utilconf

Return config values within the UtilConfig section. Equivalent to running

conf( 'UtilConfig', $value )

=cut

sub utilconf {
    return conf( "UtilConfig", @_ );
}

=head3 conf

Returns config values, given a service and the variable name to fetch

Note that this will auto-vivify $service if it doesn't exist in $config

Args: $service, $variable_name_to_fetch

Returns: value of $variable_name_to_fetch or undef

=cut

sub conf {
    my ( $service, $var ) = @_;

    $config //= read_config();

    return $config->{ $service }{ $var };
}

=head3 setconf

Given a service, variable name, and value, sets the value, creating it if necessary.

Args: $service, $variable_name, $new_value

Returns: 1 (Perl true value)

=cut

sub setconf {
    my ( $service, $var, $value) = @_;

    $config //= read_config();

    $config->{ $service }{ $var } = $value;

    return 1;
}

1;