package Bio::KBase::kbaseenv;
use strict;
use warnings;
use Try::Tiny;
use Bio::KBase::utilities;
use Bio::KBase::Logger qw( get_logger );
use Bio::KBase::Context;

use Test::Most;
# use Bio::KBase::GenomeAnnotation::Client;
# use DataFileUtil::DataFileUtilClient;
# use GenomeAnnotationAPI::GenomeAnnotationAPIClient;
# use GenomeFileUtil::GenomeFileUtilClient;
# use AssemblyUtil::AssemblyUtilClient;
# use kb_readmapper::kb_readmapperClient;
# use Workspace::WorkspaceClient;

# RAST_SDK::RAST_SDKClient

use Data::Dumper::Concise;

our $ws_client = undef;
our $ga_client = undef;
our $ac_client = undef;
our $rast_client = undef;
our $gfu_client = undef;
our $rastsdk_client = undef;
our $handle_client = undef;
our $data_file_client = undef;
my $readmapper_client = undef;

our $objects_created = [];

our $ontology_hash = undef;
our $sso_hash = undef;

sub create_context_from_client_config {
    get_logger()->warn( 'This function is now part of Bio::KBase::Context' );
    return Bio::KBase::Context::create_context_from_client_config( @_ );
}

sub log {
	my ($msg,$tag) = @_;
	if (defined($tag) && $tag eq "debugging") {
		if (defined(Bio::KBase::utilities::utilconf("debugging")) && Bio::KBase::utilities::utilconf("debugging") == 1) {
			print $msg."\n";
		}
	} else {
		print $msg."\n";
	}
}

sub data_file_client {
    my ( $parameters ) = @_;
    $parameters = Bio::KBase::utilities::args(
        $parameters,
        [],
        {
            refresh => 0
        }
    );

    undef $data_file_client if $parameters->{ refresh };

    require DataFileUtil::DataFileUtilClient;
    $data_file_client //= DataFileUtil::DataFileUtilClient->new(
        Bio::KBase::utilities::utilconf( "call_back_url" )
    );

    return $data_file_client;
}

sub ws_client {
    my ( $parameters ) = @_;
    $parameters = Bio::KBase::utilities::args( $parameters,
        [],
        {
            refresh => 0,
            url     => Bio::KBase::utilities::utilconf( "workspace-url" ),
        }
    );

    undef $ws_client if $parameters->{ refresh };

    require Workspace::WorkspaceClient;
    $ws_client //= Workspace::WorkspaceClient->new(
        $parameters->{ url },
        token => Bio::KBase::Context::token()
    );

    return $ws_client;
}

sub ga_client {
    my ( $parameters ) = @_;
    $parameters = Bio::KBase::utilities::args(
        $parameters,
        [],
        {
            refresh => 0
        }
    );

    undef $ga_client if $parameters->{ refresh };

    require GenomeAnnotationAPI::GenomeAnnotationAPIClient;
    $ga_client //= GenomeAnnotationAPI::GenomeAnnotationAPIClient->new(
        Bio::KBase::utilities::utilconf( "call_back_url" ),
        token => Bio::KBase::Context::token()
    );

    return $ga_client;
}


sub sdkrast_client {
    my ( $parameters ) = @_;
    $parameters = Bio::KBase::utilities::args(
        $parameters,
        [],
        {
            refresh => 0
        }
    );

    undef $rastsdk_client if $parameters->{ refresh };

    unless ( $rastsdk_client ) {
        require RAST_SDK::RAST_SDKClient;
        $rastsdk_client = RAST_SDK::RAST_SDKClient->new(
            Bio::KBase::utilities::utilconf( "call_back_url" ),
            token => Bio::KBase::Context::token()
        );
    }

    return $rastsdk_client;
}

sub rast_client {
    my ( $parameters ) = @_;
    $parameters = Bio::KBase::utilities::args(
        $parameters,
        [],
        {
            refresh => 0
        }
    );

    undef $rast_client if $parameters->{ refresh };

    $rast_client //= Bio::KBase::GenomeAnnotation::Client->new(
        "http://tutorial.theseed.org/services/genome_annotation"
    );

    return $rast_client;
}

sub ac_client {
    my ( $parameters ) = @_;
    $parameters = Bio::KBase::utilities::args(
        $parameters,
        [],
        {
            refresh => 0
        }
    );

    undef $ac_client if $parameters->{ refresh };

    require AssemblyUtil::AssemblyUtilClient;
    $ac_client //= AssemblyUtil::AssemblyUtilClient->new(
        Bio::KBase::utilities::utilconf( "call_back_url" ),
        token => Bio::KBase::Context::token()
    );

    return $ac_client;
}

sub gfu_client {
    my ( $parameters ) = @_;
    $parameters = Bio::KBase::utilities::args(
        $parameters,
        [],
        {
            refresh => 0
        }
    );

    undef $gfu_client if $parameters->{ refresh };

    require GenomeFileUtil::GenomeFileUtilClient;
    $gfu_client //= GenomeFileUtil::GenomeFileUtilClient->new(
        Bio::KBase::utilities::utilconf( "call_back_url" ),
        token => Bio::KBase::Context::token()
    );

    return $gfu_client;
}

sub readmapper_client {
    my ( $parameters ) = @_;
    $parameters = Bio::KBase::utilities::args(
        $parameters,
        [],
        {
            refresh => 0
        }
    );

    undef $readmapper_client if $parameters->{ refresh };

    require kb_readmapper::kb_readmapperClient;
    $readmapper_client //= kb_readmapper::kb_readmapperClient->new(
        Bio::KBase::utilities::utilconf( "call_back_url" ),
        token => Bio::KBase::Context::token()
    );

    return $readmapper_client;
}

sub handle_client {
    my ( $parameters ) = @_;
    $parameters = Bio::KBase::utilities::args(
        $parameters,
        [],
        {
            refresh => 0
        }
    );

    undef $handle_client if $parameters->{ refresh };

    unless ( $handle_client ) {
        require Bio::KBase::HandleService;
        $handle_client = Bio::KBase::HandleService->new(
            Bio::KBase::utilities::conf( "fba_tools", "handle-service-url" ),
            token => Bio::KBase::Context::token()
        );
    }

    return $handle_client;
}


#create_report: creates a report object using the KBaseReport service
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
        }
    );
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
            token   => Bio::KBase::Context::token()
        );
    }

    Bio::KBase::utilities::add_report_file( {
            path        => Bio::KBase::utilities::utilconf( "debugfile" ),
            name        => "Debug.txt",
            description => "Debug file"
        }
    ) if Bio::KBase::utilities::utilconf( 'debugging' );

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

sub assembly_to_fasta {
	my($parameters) = @_;
	$parameters = Bio::KBase::utilities::args($parameters,["ref","path","filename"],{});
	File::Path::mkpath($parameters->{path});
	if (-e $parameters->{path}."/".$parameters->{filename}) {
		unlink($parameters->{path}."/".$parameters->{filename});
	}
	if (Bio::KBase::utilities::utilconf("use_assembly_utils") == 1) {
		my $assutil = Bio::KBase::kbaseenv::ac_client();
		my $output = $assutil->get_assembly_as_fasta({"ref" => $parameters->{"ref"},"filename" => $parameters->{path}."/".$parameters->{filename}});
	} else {
		my $output = Bio::KBase::kbaseenv::ws_client()->get_objects([{"ref" => $parameters->{"ref"}}]);
		my $hc = Bio::KBase::kbaseenv::handle_client();
		$hc->download(
			$output->[0]->{data}->{fasta_handle_info}->{handle},
			$parameters->{path}."/".$parameters->{filename}
		);
	}
}

# workspace-specific functions

sub get_object {
	my ( $ws, $id ) = @_;
	my $output = Bio::KBase::kbaseenv::ws_client()->get_objects( [
	    Bio::KBase::kbaseenv::configure_ws_id($ws,$id)
	] );
	return $output->[0]->{data};
}

sub get_objects {
	my ($args,$options) = @_;
	my $input = {
		objects => $args,
	};
	my $output = Bio::KBase::kbaseenv::ws_client()->get_objects2($input);
	return $output->{data};
}

sub list_objects {
	my ($args) = @_;
	return Bio::KBase::kbaseenv::ws_client()->list_objects($args);
}

sub get_object_info {
	my ($argone,$argtwo) = @_;
	return Bio::KBase::kbaseenv::ws_client()->get_object_info($argone,$argtwo);
}

sub administer {
	my ($args) = @_;
	return Bio::KBase::kbaseenv::ws_client()->administer($args);
}

# objects
sub reset_objects_created {
    $objects_created = [];
    return;
}

sub add_object_created {
    my ( $parameters ) = @_;
    $parameters = Bio::KBase::utilities::args(
        $parameters,
        [ "ref", "description" ],
        {}
    );
    push @$objects_created, $parameters;
    return;
}

sub save_objects {
    my ( $args ) = @_;
    my $retry_count = 3;
    my $error;
    my $output;
    my $ws_client = Bio::KBase::kbaseenv::ws_client();

    while ( $retry_count ) {
        try {
            $output = $ws_client->save_objects( $args );

            for my $output_item ( @$output ) {
                my @array       = split /\./, $output_item->[ 2 ];
                my $description =
                    ( $output_item->[ 10 ] && $output_item->[ 10 ]{ description } )
                    ? $output_item->[ 10 ]{ description }
                    : $array[ 1 ] . " " . $output_item->[ 1 ];

                my $ref = join "/", map { $output_item->[ $_ ] } ( 6, 0, 4 );

                add_object_created( {
                    description => $description,
                    ref         => $ref,
                } );
            }
            undef $retry_count;
        }
        catch {

            # If there is a network glitch, wait a second and try again.
            $retry_count--;
            $error = $_;
            get_logger()->warn( $error ) if $ENV{ HARNESS_ACTIVE };
        };
    }

    Bio::KBase::utilities::error( $error ) unless $output;

    return $output;

}

sub configure_ws_id {
	my ($ws,$id,$version) = @_;
	my $input = {};
 	if ($ws =~ m/^\d+$/) {
 		$input->{wsid} = $ws;
	} else {
		$input->{workspace} = $ws;
	}
	if ($id =~ m/^\d+$/) {
		$input->{objid} = $id;
	} else {
		$input->{name} = $id;
	}
	if (defined($version)) {
		$input->{ver} = $version;
	}
	return $input;
}

sub initialize_call {
	my ( $ctx ) = @_;
	Bio::KBase::kbaseenv::reset_objects_created();
	Bio::KBase::utilities::timestamp( 1 );
	Bio::KBase::Context::set_context( $ctx );
	Bio::KBase::kbaseenv::ws_client( { refresh => 1 } );
	print "Starting ". Bio::KBase::Context::method() . " method.\n";
}

# Misc data to be loaded

sub get_ontology_hash {

    unless ( $ontology_hash && %$ontology_hash ) {
        $ontology_hash = {};

        my $ontology_map_workspace  = Bio::KBase::utilities::conf( "ModelSEED", "ontology_map_workspace" );
        my $ontology_map_string     = Bio::KBase::utilities::conf( "ModelSEED", "ontology_map_list" );
        my @ontology_map_lists = split /;/, $ontology_map_string;

        for my $ontology_map ( @ontology_map_lists ) {

            my @map_parts = split /:/, $ontology_map;
            my $output = Bio::KBase::kbaseenv::get_object(
                $ontology_map_workspace,
                $map_parts[ 1 ]
            );
            _parse_ontology_data( $output, $map_parts[ 0 ], $ontology_hash );
        }
    }
    return $ontology_hash;
}

sub _parse_ontology_data {
    my ( $output, $mapping, $ontology_hash ) = @_;

    for my $term ( keys %{ $output->{ translation } } ) {
        for my $equivalent ( @{ $output->{ translation }{ $term }{ equiv_terms } } ) {
            $ontology_hash->{ $term }{ $equivalent->{ equiv_term } } = $mapping
                if $equivalent->{ equiv_term };
        }
    }
    return;
}

sub get_sso_hash {

    unless ( $sso_hash && %$sso_hash ) {
        $sso_hash = {};

        my $output = $ws_client->get_objects( [ {
            workspace => "KBaseOntology",
            name      => "seed_subsystem_ontology"
        } ] );

        my $term_hash = $output->[ 0 ]{ data }{ term_hash };
        for my $term ( keys %$term_hash ) {
            my $term_data = $term_hash->{ $term };
            my $search_role = Bio::KBase::ObjectAPI::utilities::convertRoleToSearchRole(
                $term_data->{ name }
            );
            $term_data->{ searchname } = $search_role;
            $sso_hash->{ $term }        = $term_data;
            $sso_hash->{ $search_role } = $term_data;
            $sso_hash->{ $term_data->{ id } }   = $term_data;
        }
    }
    return $sso_hash;
}


1;
