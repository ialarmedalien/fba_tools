use Test::Most;
use Test::Perl::Critic ( -verbose => 9 );

my $base_dir = '/kb/module/';

# run perlcritic over the files
SKIP: {

    skip 'Skipping perlcritic tests', 1 unless $ENV{ PERLCRITIC };
    all_critic_ok( $base_dir );

};

done_testing;