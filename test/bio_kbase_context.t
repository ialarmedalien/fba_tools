use Test::Most;
use Path::Tiny;
use Bio::KBase::Context;
use Bio::KBase::LocalCallContext;
use Bio::KBase::kbaseenv;

my $uninitialised_error = 'Bio::KBase::Context has not been initialized';

# Bio::KBase::kbaseenv:
#   create_context_from_client_config
# Bio::KBase::utilities
#   qw( create_context )
sub test_call_context {
    my ( $args ) = @_;

    my $ctx_object      = $args->{ ctx_object };

    # calling the methods directly on the LocalCallClass object
    my $expected        = $args->{ expected };

    # call the methods indirectly through Bio::KBase::Context shortcuts
    my $pkg_functions   = $args->{ pkg_functions };

    for my $function ( qw( method provenance token user_id ) ) {
        cmp_deeply
            $ctx_object->$function(),
            $expected->{ $function },
            'field ' . $function . ' is correctly set up in context object';

        if ( $pkg_functions ) {

            my $package_function = Bio::KBase::Context->$function();
            cmp_deeply
                $package_function,
                $expected->{ $function },
                'field ' . $function . ' is correctly set up as a utility method';
            next;

        }

        throws_ok {
            Bio::KBase::Context->$function()
        }   qr/$uninitialised_error/,
            $function . " dies if context is not defined";
    }

}

subtest 'initial context and related functions' => sub {

    cmp_deeply
        Bio::KBase::Context::context(),
        undef,
        'context is initially undefined';

    for my $function ( qw( method provenance token user_id ) ) {

        throws_ok {
            Bio::KBase::Context->$function()
        }   qr/$uninitialised_error/,
            $function . " dies if context is not defined";
    }

};

subtest 'Running create_context with setcontext = 0' => sub {

    my $ctx = Bio::KBase::Context::create_context( {
        token       => 'TOKEN',
        user_id     => 'test_user_id',
        method      => 'something_awesome',
        provenance  => [ qw( this that the other ) ],
        setcontext  => 0,
    } );

    test_call_context( {
        ctx_object      => $ctx,
        expected        => {
            token       => 'TOKEN',
            user_id     => 'test_user_id',
            method      => 'something_awesome',
            provenance  => [ qw( this that the other ) ],
        },
        pkg_functions   => 0,
    } );


    # use 'user' instead of 'user_id'
    my $ctx_with_user = Bio::KBase::Context::create_context( {
        token       => 'TOKEN',
        user        => 'test_user',
        method      => 'something_ok',
        provenance  => [ qw( here there everywhere ) ],
        setcontext  => 0,
    } );

    test_call_context( {
        ctx_object      => $ctx_with_user,
        expected        => {
            token       => 'TOKEN',
            user_id     => 'test_user',
            method      => 'something_ok',
            provenance  => [ qw( here there everywhere ) ],
        },
        pkg_functions   => 0,
    } );

    cmp_deeply
        Bio::KBase::Context::context(),
        undef,
        'context is still undefined with setcontext = 0';

};

subtest 'Running create context with setcontext = 1 (the default)' => sub {

    my $ctx = Bio::KBase::Context::create_context( {
        token       => 'TOKEN_TWO',
        user        => 'test_user_two',
        provenance  => { this => 'that', the => 'other' },
    } );

    test_call_context( {
        ctx_object      => $ctx,
        expected        => {
            token       => 'TOKEN_TWO',
            user_id     => 'test_user_two',
            provenance  => { this => 'that', the => 'other' },
            method      => 'unknown',
        },
        pkg_functions   => 1,
    } );

    cmp_deeply
        $ctx,
        Bio::KBase::Context::context(),
        'context object set';
};

subtest 'create context from client config' => sub {

    {
        my @env_vars_of_interest = qw(
            KB_CLIENT_CONFIG
            KB_DEPLOYMENT_CONFIG
            KB_AUTH_TOKEN
            KBASE_TEST_TOKEN
            KBASE_TEST_USER
        );

        my %old_env;
        # save env vars but temporarily make them undef for testing
        for ( @env_vars_of_interest ) {
            $old_env{ $_ } = $ENV{ $_ };
            undef $ENV{ $_ };
        }

        cmp_deeply
            Bio::KBase::utilities::config_hash(),
            undef,
            'config is undefined';

        # remove existing context object
        Bio::KBase::Context::set_context( undef );
        cmp_deeply
            Bio::KBase::Context::context(),
            undef,
            'global context is undef';

        my $conf_file   = 'test/data/test_config.cfg';

        throws_ok {
            Bio::KBase::Context::create_context_from_client_config()
        } qr/No config file specified/,
            'No config file in params or env vars';

        throws_ok {
            Bio::KBase::Context::create_context_from_client_config({
                filename => 'random_test_file'
            })
        }   qr/Specified config file random_test_file doesn't exist!/,
            'config file specified, file not found';

        local $ENV{ KB_DEPLOYMENT_CONFIG } = 'test_file';

        throws_ok {
            Bio::KBase::Context::create_context_from_client_config()
        }   qr/Specified config file test_file doesn't exist!/,
            'KB_DEPLOYMENT_CONFIG file specified, file not found';

        local $ENV{ KB_CLIENT_CONFIG } = 'personal_test_file';

        throws_ok {
            Bio::KBase::Context::create_context_from_client_config()
        }   qr/Specified config file personal_test_file doesn't exist!/,
            'KB_CLIENT_CONFIG file specified, file not found';

        local $ENV{ KB_CLIENT_CONFIG } = 'test/data/test_config.cfg';

        cmp_deeply
            Bio::KBase::utilities::config_hash(),
            undef,
            'config is undefined';

        # file with no auth info
        throws_ok {
                Bio::KBase::Context::create_context_from_client_config()
        }   qr/Required parameter authentication token not found/,
            'file specified, no useful data therein';

        cmp_deeply
            Bio::KBase::Context::context(),
            undef,
            'global context is still undef';

        # set KB_AUTH_TOKEN so that the context creation succeeds
        local $ENV{ KB_AUTH_TOKEN } = 'THISISMYCOOLAUTHTOKENYEAH';
        my $context = Bio::KBase::Context::create_context_from_client_config({
            setcontext  => 0,
            method      => 'something',
        });

        test_call_context( {
            ctx_object      => $context,
            expected        => {
                token       => 'THISISMYCOOLAUTHTOKENYEAH',
                user_id     => 'chenry', # default user if none defined
                method      => 'something',
                provenance  => [],
                setcontext  => 0,
            },
            pkg_functions   => 0,
        } );
        cmp_deeply
            Bio::KBase::Context::context(),
            undef,
            'global context is still undef';

        dies_ok {
            Bio::KBase::Context::context()->token
        } 'context has not been initialised';


        # default settings (global context set)
        # set authentication->{ token } and { user_id }
        Bio::KBase::utilities::setconf( 'authentication', 'token', 'MYTOKEN' );
        Bio::KBase::utilities::setconf( 'authentication', 'user_id', 'DonaldDuck' );

        my $config_hash = Bio::KBase::utilities::config_hash();
        cmp_deeply
            $config_hash->{ authentication },
            {
                token   => 'MYTOKEN',
                user_id => 'DonaldDuck',
            },
            'config settings are correct';

        $context = Bio::KBase::Context::create_context_from_client_config();

        test_call_context( {
            ctx_object      => $context,
            expected        => {
                token       => 'MYTOKEN',
                user_id     => 'DonaldDuck',
                method      => 'unknown',
                provenance  => [],
                setcontext  => 1,
            },
            pkg_functions   => 1,
        } );

        isa_ok Bio::KBase::Context::context(), 'Bio::KBase::LocalCallContext';

        # restore env vars

        %ENV = ( %ENV, %old_env );

    }


};

done_testing;
