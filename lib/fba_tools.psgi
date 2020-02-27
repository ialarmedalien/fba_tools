use strict;
use warnings;

use fba_tools::fba_toolsImpl;
use fba_tools::fba_toolsServer;
use Plack::Middleware::CrossOrigin;


my $fba_tools_impl  = fba_tools::fba_toolsImpl->new;
my $server          = fba_tools::fba_toolsServer->new(
    instance_dispatch => {
        fba_tools => $fba_tools_impl,
    },
    allow_get => 0,
);

my $handler = sub { $server->handle_input( @_ ) };

$handler = Plack::Middleware::CrossOrigin->wrap(
    $handler,
    origins => "*",
    headers => "*"
);
