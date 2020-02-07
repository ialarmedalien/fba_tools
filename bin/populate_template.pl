#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Bio::KBase::Templater;
use JSON::MaybeXS qw( decode_json );
use Try::Tiny;

my ( $template, $output, $data_file, $force_overwrite );

GetOptions(
    'template|t=s'  => \$template,
    'output|o=s'    => \$output,
    'data_file|d=s' => \$data_file,
    'force!'        => \$force_overwrite,
);

die 'Please specify a valid template file using the "-t" option'
    unless $template && -r $template;

die 'Output file ' . $output . ' exists and will be overwritten. '
    . 'Please specify --force to allow overwriting.'
    if $output && -e $output && !$force_overwrite;

my $template_data;

if ( $data_file ) {

    my $file_lines;
    {
        local $/    = undef;
        open my $fh, '<', $data_file
            or die 'Cannot open ' . $data_file . ' for reading: ' . $!;
        $file_lines = <$fh>;
    }

    try {
        $template_data  = { template_data => decode_json( $file_lines ) };
    }
    catch {
        die 'Could not decode text: '
            . $_
            . "\nPlease ensure that the data file you have supplied is valid JSON.\n";
    };

}

my $out = Bio::KBase::Templater::populate_template( $template, $template_data, $output );

exit 0;

