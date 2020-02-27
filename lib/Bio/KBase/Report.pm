package Bio::KBase::Helper::ReportHelper;

use strict;
use warnings;

use Bio::KBase::utilities;
use Bio::KBase::Context;

our $objects_created = [];

sub reset_objects_created {
    $objects_created = [];
}

sub add_object_created {
    my ($parameters) = @_;
    $parameters = Bio::KBase::utilities::args($parameters,["ref","description"],{});
    push(@{$objects_created},$parameters);
}

sub create_report {
    my ( $parameters ) = @_;
    $parameters = Bio::KBase::utilities::args(
        $parameters,
        [ "workspace_name", "report_object_name" ],
        {
            warnings               => [],
            html_links             => [],
            file_links             => [],
            direct_html_link_index => undef,
            direct_html            => undef,
            message                => ""
        } );
    my $kbase_report_creator;

    if ( Bio::KBase::utilities::utilconf( "reportimpl" ) ) {

        require KBaseReport::KBaseReportImpl;
        $kbase_report_creator = KBaseReport::KBaseReportImpl->new();
        $KBaseReport::KBaseReportServer::CallContext //=
            Bio::KBase::Context::context();

    }
    else {

        require KBaseReport::KBaseReportClient;
        $kbase_report_creator = KBaseReport::KBaseReportClient->new(
            Bio::KBase::utilities::utilconf( "call_back_url" ),
            token   => Bio::KBase::Context::token(),
        );
    }

    Bio::KBase::utilities::add_report_file( {
        path        => Bio::KBase::utilities::utilconf( "debugfile" ),
        name        => "Debug.txt",
        description => "Debug file"
    } ) if Bio::KBase::utilities::utilconf( 'debugging' );

    my $data = {
        message                => Bio::KBase::utilities::report_message(),
        objects_created        => $objects_created,
        warnings               => $parameters->{ warnings },
        html_links             => Bio::KBase::utilities::report_html_files(),
        direct_html            => Bio::KBase::utilities::report_html(),
        direct_html_link_index => $parameters->{ direct_html_link_index },
        file_links             => Bio::KBase::utilities::report_files(),
        report_object_name     => $parameters->{ report_object_name },
        workspace_name         => $parameters->{ workspace_name }
    };

    return $kbase_report_creator->create_extended_report( $data );

}

1;