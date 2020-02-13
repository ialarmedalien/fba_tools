use Test::Most;
use Test::Output;
use Bio::KBase::ObjectAPI::KBaseFBA::FBAModel;

require_ok 'Bio::KBase::ObjectAPI::functions';

subtest 'dump_json' => sub {

    lives_ok {
    	Bio::KBase::ObjectAPI::functions::dump_json( { this => 'that' }, 'test' );
    } 'testing dump_json with a simple structure';

    my $obj = Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->new( id => 'test' );
    lives_ok {
        Bio::KBase::ObjectAPI::functions::dump_json( $obj, 'impl' );
    } 'testing with a more complex object';

};

done_testing;