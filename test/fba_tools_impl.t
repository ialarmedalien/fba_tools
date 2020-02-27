use Test::Most;
use KBaseTestContext;
use Bio::KBase::Logger qw( get_logger );
use Bio::KBase::utilities;
use Bio::KBase::ObjectAPI::functions;

my $logger      = get_logger();
my $test_ws     = KBaseTestContext->test_ws();
my $base_dir    = KBaseTestContext->base_dir();

require_ok 'fba_tools::fba_toolsImpl';

subtest 'initialisation' => sub {

    cmp_deeply
        $Bio::KBase::utilities::loghandler,
        undef,
        'log handler not yet defined';

    cmp_deeply
        $Bio::KBase::ObjectAPI::functions::handler,
        undef,
        'function handler not yet defined';

    my $old_config          = delete $ENV{ KB_DEPLOYMENT_CONFIG };
    my $old_callback_url    = delete $ENV{ SDK_CALLBACK_URL };

    # failures:
    {
        undef $ENV{ KB_DEPLOYMENT_CONFIG };
        undef $ENV{ SDK_CALLBACK_URL };

        my $fail_message = fba_tools::fba_toolsImpl::init_error_message();

        throws_ok {
            fba_tools::fba_toolsImpl->new
        } qr/$fail_message/,
            'Missing required env vars';

        local $ENV{ SDK_CALLBACK_URL } = 'http://example.com';

        # no config file
        throws_ok {
            fba_tools::fba_toolsImpl->new
        } qr/$fail_message/,
            'Missing required config file env var';

        # config file does not exist
        local $ENV{ KB_DEPLOYMENT_CONFIG } = '/file/not/found';
        throws_ok {
            fba_tools::fba_toolsImpl->new
        } qr!Specified config file /file/not/found doesn't exist!,
            'file does not exist';


        # config file for testing
        local $ENV{ KB_DEPLOYMENT_CONFIG } = $base_dir . 'test/data/test_config.cfg';

        my $impl = fba_tools::fba_toolsImpl->new;

        isa_ok $impl, 'fba_tools::fba_toolsImpl';

        is Bio::KBase::utilities::utilconf( "call_back_url" ),
            'http://example.com',
            'callback URL set correctly';

        my $endpoint = Bio::KBase::utilities::conf( "fba_tools", "kbase-endpoint" );

        if ( $endpoint && $endpoint =~ m!appdev\.kbase\.us! ) {
            is Bio::KBase::utilities::conf( "ModelSEED", "ontology_map_workspace" ),
                "janakakbase:narrative_1550174613022",
                'appropriate ontology map workspace set';
        }

        isa_ok $Bio::KBase::utilities::loghandler,
            'fba_tools::fba_toolsImpl';


        isa_ok $Bio::KBase::ObjectAPI::functions::handler,
            'fba_tools::fba_toolsImpl';

    }

    # restore original config setup
    $ENV{ KB_DEPLOYMENT_CONFIG }    = $old_config;
    $ENV{ SDK_CALLBACK_URL }        = $old_callback_url;


};


=cut

subtest 'util_finalize_call' => sub {

    for my $args ( @args ) {





    }

    my $report = Bio::KBase::kbaseenv::create_report( {
        workspace_name         => $params->{ workspace },
        report_object_name     => $params->{ report_name },
        direct_html_link_index => $params->{ direct_html_link_index },
    } );




};



    $params = $self->util_initialize_call( $params, $ctx );
    $return = Bio::KBase::ObjectAPI::functions::func_run_model_chacterization_pipeline( $params );

    $self->util_finalize_call( {
        output      => $return,
        workspace   => $params->{ workspace },
        report_name => $params->{ fbamodel_output_id } . ".report",
    } );
=cut

done_testing();