use Test::Most;
use Path::Tiny;
use Bio::KBase::LocalCallContext;
use Bio::KBase::kbaseenv;

require_ok 'Bio::KBase::utilities';

subtest 'args' => sub {

    # failures
    my @failed_tests = (
    {
        desc    => 'incorrect $args format: string',
        args    => [ qw( test ) ],
        message => qr/Arguments must be a hashref/,
    },
    {
        desc    => 'incorrect $args format: arrayref',
        args    => [ [ 'test', 'case' ] ],
        message => qr/Arguments must be a hashref/,
    },
    {
        desc    => 'incorrect mandatory args format',
        args    => [ undef, { this => 'that' } ],
        message => qr/Mandatory arguments must be an arrayref/,
    },
    {
        desc    => 'incorrect optional args format',
        args    => [ undef, [ qw( this that ) ], 1, { this => 'that' } ],
        message => qr/Optional arguments must be a hashref/,
    },
    {
        desc    => 'incorrect substitutions format',
        args    => [ {}, [ qw( this that ) ], { this => 'that' }, [] ],
        message => qr/Substitutions must be a hashref/,
    },
    {
        desc    => 'Expected failure: missing mandatory args',
        args    => [ undef, [ 'this', 'that', 'the other' ] ],
        message => qr/Mandatory arguments missing: this; that; the other/,
    },
    {
        desc    => 'Expected failure: missing mandatory args',
        args    => [ { this => 'that' }, [ 'this', 'that', 'the other' ] ],
        message => qr/Mandatory arguments missing: that; the other/,
    }
    );


    for ( @failed_tests ) {

        throws_ok {
            Bio::KBase::utilities::args( @{ $_->{ args } } )
        }   $_->{ message },
            $_->{ desc };

    }

    # successful calls
    cmp_deeply
        Bio::KBase::utilities::args(),
        {},
        'arguments parsed correctly';

    my @successful_tests = (
        {
            desc    => 'empty arguments',
            args    => [ {}, [], {}, {} ],
            expect  => {},
        },
        {
            desc    => 'mandatory args passed',
            args    => [
                { this => 'that', here => 'there' },
                [ 'this', 'here' ]
            ],
            expect  => { this => 'that', here => 'there' },
        },
        {
            desc    => 'optional arguments, unused',
            args    => [
                { this => 'that', here => 'there' },
                undef,
                { this => 'these', }
            ],
            expect  => { this => 'that', here => 'there' },
        },
        {
            desc    => 'optional arguments, used',
            args    => [
                { this => 'that', here => 'there' },
                undef,
                { pip => 'pop', here => 'be dragons', this => undef, foo => undef },
            ],
            expect  => { this => 'that', here => 'there', pip => 'pop', foo => undef },
        },
        {
            desc    => 'empty arguments',
            args    => [ {} ],
            expect  => {},
        },
        {
            desc    => 'single substitution, no overlap',
            args    => [
                { this => 'that', here => 'there' },
                undef,
                undef,
                { pip => 'pop' }
            ],
            expect  => { this => 'that', here => 'there', pip => undef },
        },
        {
            desc    => 'single substitution, substitution key matches',
            args    => [
                { this => 'that', here => 'there' },
                undef,
                undef,
                { this => 'the other' }
            ],
            expect  => { this => undef, here => 'there' },
        },
        {
            desc    => 'single substitution, substitution value matches',
            args    => [
                { this => 'that', here => 'there' },
                undef,
                undef,
                { place => 'here' }
            ],
            expect  => { this => 'that', here => 'there', place => 'there' },
        },
    );

    for ( @successful_tests ) {
        my $result = Bio::KBase::utilities::args( @{ $_->{ args } } );
        cmp_deeply
            $result,
            $_->{ expect },
            $_->{ desc },
            or diag explain {
                input   => $_->{ args },
                got     => $result,
                expect  => $_->{ expect },
            };
    }

};


subtest 'reading, getting, and setting config data' => sub {

    {

        cmp_deeply
            Bio::KBase::utilities::config_hash(),
            undef,
            'config is initially undefined';

        my $old_service = delete $ENV{ KB_SERVICE_NAME };
        my $old_conf    = delete $ENV{ KB_DEPLOYMENT_CONFIG };

        my $service     = 'Testing service';
        my $conf_file   = 'test/data/test_config.cfg';

        # undef env vars
        undef $ENV{ $_ } for qw( KB_DEPLOYMENT_CONFIG KB_SERVICE_NAME );

        throws_ok {
            Bio::KBase::utilities::read_config()
        }   qr/No service specified/,
            'No service specified and no KB_SERVICE_NAME env var';

        throws_ok {
            Bio::KBase::utilities::read_config({
                service => $service,
            })
        }   qr/No config file specified/,
            'Service specified, no config file';

        local $ENV{ KB_SERVICE_NAME } = $service;
        throws_ok {
            Bio::KBase::utilities::read_config()
        }   qr/No config file specified/,
            'Service specified, no KB_DEPLOYMENT_CONFIG file';


        throws_ok {
            Bio::KBase::utilities::read_config({ filename => 'random_test_file' })
        }   qr/Specified config file random_test_file doesn't exist!/,
            'Service and file specified, file not found';

        local $ENV{ KB_DEPLOYMENT_CONFIG } = 'test_file';

        throws_ok {
            Bio::KBase::utilities::read_config()
        }   qr/Specified config file test_file doesn't exist!/,
            'Service and file specified, file not found';

        my $expected = {
            'Random Stuff'  => {
                'i-can-haz' => 'cheezeburger',
            },
            'UtilConfig'    => {
                call_back_url   => $ENV{ SDK_CALLBACK_URL },
                debugfile       => '/kb/module/work/tmp/debug.txt',
                debugging       => 0,
                fulltrace       => 1,
                reportimpl      => 0,
                scratch         => '/kb/module/work/tmp',
                token           => undef,
                'my.fave.descriptor'    => 'this',
                'my.object.identifier'  => 'self',
            },
            'Testing service'   => {},
        };

        # success!
        cmp_deeply
            Bio::KBase::utilities::read_config( {
                filename    => $conf_file,
                service     => $service,
            } ),
            $expected,
            'read ' . $service . ' config successfully';

        is Bio::KBase::utilities::utilconf( 'debugfile' ),
            '/kb/module/work/tmp/debug.txt',
            'value present in UtilConfig';

        is Bio::KBase::utilities::utilconf( 'not.my.idea' ),
            undef,
            'value not present in UtilConfig returns undef';

        is Bio::KBase::utilities::conf( 'RocketShip', 'rocket_launch_sequence' ),
            undef,
            'service and value not present in $config';

        ok Bio::KBase::utilities::setconf( 'RocketShip', 'rocket_launch_sequence', 'begin' ),
            'set value successfully';

        is Bio::KBase::utilities::conf( 'RocketShip', 'rocket_launch_sequence' ),
            'begin',
            'service and value now present in $config';

        ok Bio::KBase::utilities::setconf( 'Testing service', 'Number_of_tests', 200 ),
            'set value successfully';

        is Bio::KBase::utilities::conf( 'Testing service', 'Number_of_tests' ),
            '200',
            'service and value now present in $config';

        ok Bio::KBase::utilities::setconf( 'Testing service', 'Number_of_tests', undef ),
            'set value to undef successfully';

        is Bio::KBase::utilities::conf( 'Testing service', 'Number_of_tests' ),
            undef,
            'service and value now present in $config';

        cmp_deeply
            Bio::KBase::utilities::config_hash(),
            {
                'Random Stuff'  => {
                    'i-can-haz' => 'cheezeburger',
                },
                'UtilConfig'    => {
                    call_back_url   => $ENV{ SDK_CALLBACK_URL },
                    debugfile       => '/kb/module/work/tmp/debug.txt',
                    debugging       => 0,
                    fulltrace       => 1,
                    reportimpl      => 0,
                    scratch         => '/kb/module/work/tmp',
                    token           => undef,
                    'my.fave.descriptor'    => 'this',
                    'my.object.identifier'  => 'self',
                },
                'Testing service'   => {
                    'Number_of_tests'   => undef,
                },
                'RocketShip'        => {
                    'rocket_launch_sequence'    => 'begin',
                },
            },
            'config hash has the expected structure'
            or diag explain {
                config_hash => Bio::KBase::utilities::config_hash()
            };

        # reset env vars
        $ENV{ KB_SERVICE_NAME } = $old_service;
        $ENV{ KB_DEPLOYMENT_CONFIG } = $old_conf;

    }

};


done_testing;
