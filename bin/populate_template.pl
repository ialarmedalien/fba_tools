#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long qw( GetOptionsFromArray );
use Pod::Usage;
use Bio::KBase::Templater;

sub parse_options {

    my ( @args ) = @_;

    my ( $template, $output, $data_file, $force_overwrite, $help );

    GetOptionsFromArray(
        \@args,
        'template|t=s'  => \$template,
        'output|o=s'    => \$output,
        'data_file|d=s' => \$data_file,
        'force!'        => \$force_overwrite,
        'help|h'        => \$help,
    );

    pod2usage( -verbose => 2, -exitval => 1 ) if $help;

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

    return Bio::KBase::Templater::populate_template( $template, $template_data, $output );

}

parse_options( @ARGV );

exit 0;

__END__

=head1 NAME

populate_template - render a template

=head1 SYNOPSIS

perl populate_template.pl -t template_file [-d data_file] [-o output_file] [-f]

    -t template_file    template file (required)
    -d data_file        file containing JSON-formatted data (optional)
    -o output_file      save output to this file (optional)
    -f                  force overwriting of existing output file
    -h                  print this help message

=head1 ARGUMENTS

=over 8

=item B<-h> or B<--help>

Prints this help and exits.

=item B<-t> or B<--template>

Required. Absolute path to the file to be used as the template.

=item B<-d> or B<--data_file>

Optional. Absolute path to a file containing data for populating the template. The data
must be in valid JSON format.

=item B<-o> or B<--output>

Optional. Path to a file to write the output to. Output will be sent to STDOUT if none is
specified.

=item B<--force>

In conjunction with -o, will force the overwriting of an existing file with the
output from the script.

=back

=head1 DESCRIPTION

B<This program> will read the template and (optional) data file and will
generate output from it, writing it to STDOUT or to a specified output file.

=cut