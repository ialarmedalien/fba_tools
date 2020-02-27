#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use fba_tools::fba_toolsImpl;
use Bio::KBase::Context;
local $| = 1;

Bio::KBase::Context::create_context_from_client_config();
my $impl = fba_tools::fba_toolsImpl->new();

my $output = Bio::KBase::ObjectAPI::functions::func_build_metagenome_metabolic_model({
	workspace => 49110,
	input_ref => "TestMetagenomeAssembly",
	fbamodel_output_id => "TestMetagenomeModel",
	media_id => "Carbon-D-Glucose",
	media_workspace => "KBaseMedia",
	gapfill_model => 1,
	gff_file => "/Users/chenry/workspace/PNNLSFA/SoilSFA_WA_nrKO.gff"
});