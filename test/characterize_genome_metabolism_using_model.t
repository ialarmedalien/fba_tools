use Test::Most;
use KBaseTestContext;
use Bio::KBase::Logger qw( get_logger );
use fba_tools::fba_toolsImpl;

my $logger  = get_logger();
my $test_ws = KBaseTestContext->test_ws();
my $impl    = KBaseTestContext->init_fba_tools_handler();

$logger->debug( 'loaded object API, etc.' ) if $impl;

# plan skip_all => 'Callback server not available' unless $impl;

subtest 'running characterize_genome_metabolism_using_model' => sub {

    $logger->debug( 'starting up method tests' );
    lives_ok{
        $impl->characterize_genome_metabolism_using_model({
            workspace => $test_ws,
            genome_id => "Escherichia_coli",
        });
    } "characterize_genome_metabolism_using_model";

};

done_testing();
