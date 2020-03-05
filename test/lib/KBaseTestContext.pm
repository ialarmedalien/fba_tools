package KBaseTestContext;
# A module containing test helpers and data

use Test::Most;
use Bio::KBase::Context;
use fba_tools::fba_toolsImpl;
use Try::Tiny;

my $impl;

sub base_dir { '/kb/module/' }

sub test_ws  { 'chenry:narrative_1504151898593' }

=head3

Create a new fba_tools::fba_toolsImpl object, bailing out of the rest of the
tests if the object cannot be created.

=cut

sub init_fba_tools_handler {

    unless ( $impl ) {
        subtest 'creating fba tools implementation' => sub {

            try {
                Bio::KBase::Context::create_context_from_client_config();
                $impl = fba_tools::fba_toolsImpl->new();
                isa_ok $impl, 'fba_tools::fba_toolsImpl';
            }
            catch {
                warn $_;
            };

            plan skip_all => 'Cannot proceed without fba_tools impl running'
                unless $impl;

        };
    }

    return $impl;

}


1;
