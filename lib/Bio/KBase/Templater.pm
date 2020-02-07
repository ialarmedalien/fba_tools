package Bio::KBase::Templater;

use strict;
use warnings;

use JSON::MaybeXS;
use Template;
use Template::Plugin::JSON;
use Try::Tiny;

=head2 populate_template

Given a template, $template_file, populate it with $template_data and send the
output to $output. Very thin wrapper around Template::Toolkit's 'process' that
includes TT object initialisation.

Args:

$template       # input template; possible formats:
                #   - filename (absolute or relative to INCLUDE_PATH)
                #   - file handle reference
                #   - GLOB from which template can be read

$template_data  # data to use in the template (hashref; optional)

$output         # where to write the output to; possible formats:
                #   - filename (absolute)
                #   - open file GLOB
                #   - reference to a scalar variable to append output to
                #   - reference to a sub which is called with output as a param
                #   - reference to any object with a print() method

$arguments      # optional arguments to set binmode or IO layer (e.g. utf8)


Returns:

$output, the populated template

=cut

sub populate_template {
    my ( $template, $template_data, $output, $arguments ) = @_;

    my $config  = template_config() // { TRIM => 1 };
    my $tt      = Template->new( $config )
        or die $Template::ERROR . "\n";

    return $tt->process( $template, $template_data )
        unless $output;

    $tt->process( $template, $template_data, $output, { binmode => ':utf8' } )
        or die $tt->error() . "\n";

    return $output;

}

sub template_config {

    {}

}

1;