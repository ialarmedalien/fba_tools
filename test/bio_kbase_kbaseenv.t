use Test::Most;
use Test::Output;
use Moo;
use feature qw( say );
use Data::Dumper::Concise;

require_ok 'Bio::KBase::kbaseenv';
use Bio::KBase::utilities;
use Bio::KBase::ObjectAPI::functions;

my $object = {
    ref         => 'my_ref',
    description => 'an object added for fun',
};

subtest 'objects_created manipulation' => sub {

    cmp_deeply
        $Bio::KBase::kbaseenv::objects_created,
        [],
        'objects_created is initially empty';

    lives_ok {
        Bio::KBase::kbaseenv::add_object_created( $object )
    } 'successfully added an object';

    cmp_deeply $Bio::KBase::kbaseenv::objects_created,
        [ $object ],
        'objects_created looks as expected';

    lives_ok {
        Bio::KBase::kbaseenv::reset_objects_created();
    } 'resetting objects created lives';

    cmp_deeply $Bio::KBase::kbaseenv::objects_created,
        [],
        'objects_created is empty again';

};

subtest 'save_objects' => sub {

    my $max_retries = 3;

    {
        package TimedOutWSClient;

        use strict;
        use warnings;
        use Moo;

        has 'acc'           => ( is => 'rw', default => 0 );
        has 'max_retries'   => ( is => 'ro', default => $max_retries );
        has 'output_data'   => ( is => 'ro', default => sub { [] } );

        sub save_objects {
            my $self = shift;
            $self->acc( $self->acc + 1 );

            # if acc is greater than max_retries, return the data;
            return $self->output_data if $self->acc > $self->max_retries;

            # otherwise, die with a message
            die "Goodbye cruel world number " . $self->acc;
        }

        1;

    }

    Bio::KBase::kbaseenv::reset_objects_created();
    cmp_deeply $Bio::KBase::kbaseenv::objects_created,
        [],
        'objects_created is empty again';

    my $fake_output_data = [
        [
            233,                            # 0
            "Escherichia_coli.mdl.base",    # 1
            "KBaseFBA.FBAModel-13.0",       # 2
            "2020-02-20T20:44:28+0000",
            105,                            # 4
            "whodidthisagain",
            8248,                           # 6
            "somesortoffunreference",
            "fa09c6bcbb1b1d2b97553a7daa961874",
            1987851,
            {                               # 10
                Genome                => "8248/193/2",
                Name                  => "Escherichia_coli.mdl.base",
                Source                => "KBase",
                "Source ID"           => "Escherichia_coli.mdl.base",
                Type                  => "GenomeScale"
            }
        ]
    ];

    my $timedout_client = TimedOutWSClient->new( output_data => $fake_output_data );

    {
        local *Bio::KBase::kbaseenv::ws_client = sub { $timedout_client };

        my $combined_output = combined_from {

            throws_ok {
                Bio::KBase::kbaseenv::save_objects( { this => 'that' } );
            } qr/Goodbye cruel world/,
                'testing save_objects with network timeout';

        };

        my @goodbyes = grep { /Goodbye cruel world/ } split /[\r\n]/, $combined_output;
        cmp_ok scalar @goodbyes,
            '==',
            3,
            'three retries before dying';

    }

    # new ws client that succeeds
    $timedout_client = TimedOutWSClient->new(
        max_retries => 0,
        output_data => $fake_output_data,
    );

    {
        local *Bio::KBase::kbaseenv::ws_client = sub { $timedout_client };

        cmp_deeply
            Bio::KBase::kbaseenv::save_objects( { this => 'that' } ),
            $fake_output_data,
            'data successfully saved by fake ws object';

        cmp_deeply
            $Bio::KBase::kbaseenv::objects_created,
            [
                {
                    ref         => '8248/233/105',
                    description => 'FBAModel-13 Escherichia_coli.mdl.base',
                }
            ],
            'Objects created contains appropriate data';
    }

    my $three_outputs = [
        [
            123,                            # 0
            "Escherichia_coli.mdl.base",    # 1
            "KBaseFBA.FBAModel-13.0",       # 2
            "2020-02-20T20:44:28+0000",
            666,                            # 4
            "whodidthisagain",
            91735,                           # 6
            "somesortoffunreference",
            "fa09c6bcbb1b1d2b97553a7daa961874",
            1987851,
            {                               # 10
                Name        => "Escherichia_coli.mdl.base",
                Source      => "KBase",
                description => "This is super cool"
            }
        ],
        [
            456,                            # 0
            "Escherichia_coli.mdl.base",    # 1
            "Crazy.Sexy.Cool",              # 2
            "2020-02-20T20:44:28+0000",
            666,                            # 4
            "whodidthisagain",
            91735,                           # 6
            "somesortoffunreference",
            "fa09c6bcbb1b1d2b97553a7daa961874",
            1987851,
            {                               # 10
                Name                  => "Escherichia_coli.mdl.base",
                Source                => "KBase",
            }
        ],
        [
            789,                            # 0
            "Escherichia_coli.mdl.base",    # 1
            "KBaseFBA.FBAModel-13.0",       # 2
            "2020-02-20T20:44:28+0000",
            666,                            # 4
            "whodidthisagain",
            91735,                           # 6
            "somesortoffunreference",
            "fa09c6bcbb1b1d2b97553a7daa961874",
            1987851,
            {                               # 10
                description => 'mundane and boring',
            }
        ],
    ];
    my $three_outputs_obj_creation_data = [
    {
        ref         => '91735/123/666',
        description => "This is super cool",
    },{
        ref         => '91735/456/666',
        description => 'Sexy Escherichia_coli.mdl.base',
    },{
        ref         => '91735/789/666',
        description => 'mundane and boring'
    }
    ];

    $timedout_client = TimedOutWSClient->new(
        max_retries => 2,
        output_data => $three_outputs,
    );

    {
        local *Bio::KBase::kbaseenv::ws_client = sub { $timedout_client };


        my $combined_output = combined_from {
            cmp_deeply
                Bio::KBase::kbaseenv::save_objects( { this => 'that' } ),
                $three_outputs,
                'data successfully saved by fake ws object';
        };

        my @goodbyes = grep { /Goodbye cruel world/ } split /[\r\n]/, $combined_output;
        cmp_ok scalar @goodbyes,
            '==',
            2,
            'two retries before success';

        cmp_deeply
            $Bio::KBase::kbaseenv::objects_created,
            [
                {
                    ref         => '8248/233/105',
                    description => 'FBAModel-13 Escherichia_coli.mdl.base',
                },
                @$three_outputs_obj_creation_data,
            ],
            'Objects created contains appropriate data';
    }

};

# requires the full test config to have been loaded
=cut
subtest 'get_ontology_hash' => sub {

    local $ENV{ KB_SERVICE_NAME } = 'Testing service';

    my $ontology_map_list = Bio::KBase::utilities::conf( 'ModelSEED', 'ontology_map_list' );
# ontology_map_list=KEGGKO:KEGG_KO.ModelSEED;EC:EBI_EC.ModelSEED;MetaCyc:Metacyc_RXN.ModelSEED;SSO:SSO.ModelSEED;KEGGRXN:KEGG_RXN.ModelSEED

    my $ontology_hash = Bio::KBase::kbaseenv::get_ontology_hash();

    Bio::KBase::ObjectAPI::functions::dump_json( $ontology_hash, 'ontology_hash' );
    ok 'computer';

};

subtest 'get_sso_hash' => sub {

    my $sso_hash = Bio::KBase::kbaseenv::get_sso_hash();

    Bio::KBase::ObjectAPI::functions::dump_json( $sso_hash, 'sso_hash' );
    ok 'computer';

};
=cut

done_testing;