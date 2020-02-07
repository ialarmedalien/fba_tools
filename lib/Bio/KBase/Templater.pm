package Bio::KBase::Templater;

use strict;
use warnings;
use Template;
use JSON::MaybeXS;
use Template::Plugin::JSON;

=head2 populate_template

Given a template, $template_file, populate it with $template_data and send the
output to $output. The



Args:

$template       # input template; possible formats:
                #   - filename (absolute or relative to INCLUDE_PATH)
                #   - file handle reference
                #   - GLOB from which template can be read

$template_data  # data to use in the template (hashref; optional)

$output         # where to write the output to; possible formats:
                #   - filename (absolute or relative to OUTPUT_PATH)
                #   - open file GLOB
                #   - reference to a scalar variable to append output to
                #   - reference to a sub which is called with output as a param
                #   - reference to any object with a print() method

$arguments      # optional arguments to set binmode or IO layer (e.g. utf8)


returns $output, the populated template

=cut

sub populate_template {
    my ( $template, $template_data, $output, $arguments ) = @_;

    my $config  = template_config();
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