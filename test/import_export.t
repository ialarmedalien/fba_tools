use Test::Most;
use KBaseTestContext;
use Bio::KBase::utilities;
use Bio::KBase::Logger qw( get_logger );
use fba_tools::fba_toolsImpl;

my $logger  = get_logger();
my $test_ws = KBaseTestContext->test_ws();
my $impl    = KBaseTestContext->init_fba_tools_handler();

subtest 'importing from different file formats' => sub {

    lives_ok {
        $impl->excel_file_to_model( {
                model_file => {
                    path => Bio::KBase::utilities::conf( "fba_tools", "testdir" )
                        . "/test_model.xlsx"
                },
                model_name     => "excel_import",
                workspace_name => $test_ws,
                genome         => $test_ws . "/Escherichia_coli",
                biomass        => [ "bio1" ] } )
    }
    'import model from excel';

    lives_ok {
        $impl->sbml_file_to_model( {
                model_file => {
                    path => Bio::KBase::utilities::conf( "fba_tools", "testdir" )
                        . "/e_coli_core.xml"
                },
                model_name     => "sbml_test",
                workspace_name => $test_ws,
                genome         => $test_ws . "/Escherichia_coli",
                biomass        => [ "R_BIOMASS_Ecoli_core_w_GAM" ] } )
    }
    'SBML import: test "R_" prefix';

    lives_ok {
        $impl->sbml_file_to_model( {
                model_file => {
                    path => Bio::KBase::utilities::conf( "fba_tools", "testdir" )
                        . "/PUBLIC_150.xml"
                },
                model_name     => "sbml_test2",
                workspace_name => $test_ws,
                genome         => $test_ws . "/Escherichia_coli",
                biomass        => [ "bio00006" ] } )
    }
    'SBML import: test "_reference" error';

    lives_ok {
        $impl->sbml_file_to_model( {
                model_file => {
                    path => Bio::KBase::utilities::conf( "fba_tools", "testdir" )
                        . "/Community_model.sbml"
                },
                model_name     => "sbml_test3",
                workspace_name => $test_ws,
                genome         => $test_ws . "/Escherichia_coli",
                biomass        => [ "bio1", "bio2", 'bio3' ] } )
    }
    'SBML import: community model';

    lives_ok {
        $impl->sbml_file_to_model( {
                model_file => {
                    path => Bio::KBase::utilities::conf( "fba_tools", "testdir" )
                        . "/iYL1228.xml"
                },
                model_name     => "sbml_test4",
                workspace_name => $test_ws,
                genome         => $test_ws . "/Escherichia_coli",
                biomass        => [ "R_BIOMASS_" ] } )
    }
    'SBML import: annother model from BiGG';

    lives_ok {
        $impl->sbml_file_to_model( {
                model_file => {
                    path => Bio::KBase::utilities::conf( "fba_tools", "testdir" )
                        . "/Ec_iJR904.xml"
                },
                model_name     => "sbml_test5",
                workspace_name => $test_ws,
                genome         => $test_ws . "/Escherichia_coli",
                biomass        => [ "bio1" ] } )
    }
    'SBML import: yet annother model from BiGG';

    lives_ok {
        $impl->sbml_file_to_model( {
                model_file => {
                    path => Bio::KBase::utilities::conf( "fba_tools", "testdir" )
                        . "/iMB155.xml"
                },
                model_name     => "sbml_test6",
                workspace_name => $test_ws,
                genome         => $test_ws . "/Escherichia_coli",
                biomass        => [ "R_BIOMASS" ] } )
    }
    'SBML import: yet annother model from BiGG';

    dies_ok {
        $impl->sbml_file_to_model( {
                model_file => {
                    path => Bio::KBase::utilities::conf( "fba_tools", "testdir" )
                        . "/PUBLIC_150.xml"
                },
                model_name     => "better_fail",
                workspace_name => $test_ws,
                genome         => $test_ws . "/Escherichia_coli",
                biomass        => [ "foo" ] } )
    }
    'SBML import: biomass not found';
    print $@. "\n";

    dies_ok {
        $impl->tsv_file_to_model( {
                model_file => {
                    path => Bio::KBase::utilities::conf( "fba_tools", "testdir" )
                        . "/FBAModelReactions.tsv"
                },
                model_name     => "Pickaxe",
                workspace_name => $test_ws,
                biomass        => [],
                compounds_file => {
                    path => Bio::KBase::utilities::conf( "fba_tools", "testdir" )
                        . "/FBAModelCompounds.tsv"
                } } )
    }
    'TSV to Model: invalid compound identifier';
    print $@. "\n";

    lives_ok {
        $impl->tsv_file_to_model( {
                model_file => {
                    path => Bio::KBase::utilities::conf( "fba_tools", "testdir" )
                        . "/test_model-reactions.tsv"
                },
                model_name     => "tsv_import",
                workspace_name => $test_ws,
                genome         => $test_ws . "/Escherichia_coli",
                ,
                biomass        => [ "bio1" ],
                compounds_file => {
                    path => Bio::KBase::utilities::conf( "fba_tools", "testdir" )
                        . "/test_model-compounds.tsv"
                } } )
    }
    'import model from tsv';

};

subtest 'exporting model to different file formats' => sub {

lives_ok {
    $impl->model_to_excel_file( {
            input_ref => $test_ws . "/test_model"
        } )
}
'export model as excel';

lives_ok {
    $impl->model_to_sbml_file( {
            input_ref => $test_ws . "/test_model"
        } )
}
'export model as sbml';

lives_ok {
    $impl->model_to_tsv_file( {
            input_ref => $test_ws . "/test_model"
        } )
}
'export model as tsv';

};

subtest 'export FBA' => sub {
    lives_ok {
        $impl->fba_to_excel_file( {
                input_ref => $test_ws . "/test_minimal_fba"
            } )
    }
    'export fba as excel';

    lives_ok {
        $impl->fba_to_tsv_file( {
                input_ref => $test_ws . "/test_minimal_fba"
            } )
    }
    'export fba as tsv';
};

subtest 'TSV to media tests' => sub {
    lives_ok {
        $impl->tsv_file_to_media( {
                media_file => {
                    path => Bio::KBase::utilities::conf( "fba_tools", "testdir" )
                        . "/media_example.tsv"
                },
                media_name     => "tsv_media",
                workspace_name => $test_ws
            } )
    }
    'TSV to media';

    lives_ok {
        $impl->tsv_file_to_media( {
                media_file => {
                    path => Bio::KBase::utilities::conf( "fba_tools", "testdir" )
                        . "/test_media.tsv"
                },
                media_name     => "tsv_media2",
                workspace_name => $test_ws
            } )
    }
    'TSV to media 2';

    lives_ok {
        $impl->tsv_file_to_media( {
                media_file => {
                    path => Bio::KBase::utilities::conf( "fba_tools", "testdir" )
                        . "/medio.tsv"
                },
                media_name     => "tsv_media3",
                workspace_name => $test_ws
            } )
    }
    'TSV to media: blank lines and trailing spaces';

};

subtest 'excel to media' => sub {
    lives_ok {
        $impl->excel_file_to_media( {
                media_file => {
                    path => Bio::KBase::utilities::conf( "fba_tools", "testdir" )
                        . "/media_example.xls"
                },
                media_name     => "xls_media",
                workspace_name => $test_ws
            } )
    }
    'Excel to media';

    lives_ok {
        $impl->excel_file_to_media( {
                media_file => {
                    path => Bio::KBase::utilities::conf( "fba_tools", "testdir" )
                        . "/test_media.xls"
                },
                media_name     => "xls_media2",
                workspace_name => $test_ws
            } )
    }
    'Excel to media 2';
};

subtest 'media to TSV / excel' => sub {
    lives_ok {
        $impl->media_to_tsv_file( {
                input_ref => "KBaseMedia/Carbon-D-Glucose"
            } )
    }
    'media to tsv file';

    lives_ok {
        $impl->media_to_excel_file( {
                input_ref => "KBaseMedia/Carbon-D-Glucose"
            } )
    }
    'media to excel file';

};

subtest 'import to phenotype_set' => sub {
    lives_ok {
        $impl->tsv_file_to_phenotype_set( {
                phenotype_set_file => {
                    path => Bio::KBase::utilities::conf( "fba_tools", "testdir" )
                        . "/JZ_UW_Phynotype_Set_test.txt"
                },
                phenotype_set_name => "return_delimited",
                workspace_name     => $test_ws,
                genome             => $test_ws . "/Escherichia_coli"
            } )
    }
    'TSV to Phenotype Set: import return delimented';

    lives_ok {
        $impl->tsv_file_to_phenotype_set( {
                phenotype_set_file => {
                    path => Bio::KBase::utilities::conf( "fba_tools", "testdir" )
                        . "/NewPhenotypeSet.tsv"
                },
                phenotype_set_name => "test_phenotype_set",
                workspace_name     => $test_ws,
                genome             => $test_ws . "/Escherichia_coli"
            } )
    }
    'TSV to Phenotype Set: custom columns';

    dies_ok {
        $impl->tsv_file_to_phenotype_set( {
                phenotype_set_file => {
                    path => Bio::KBase::utilities::conf( "fba_tools", "testdir" )
                        . "/EmptyPhenotypeSet.tsv"
                },
                phenotype_set_name => "test_phenotype_set",
                workspace_name     => $test_ws,
                genome             => $test_ws . "/Escherichia_coli"
            } )
    }
    'import empty phenotype set fails';
    print $@. "\n";
};

subtest 'export phenotype set' => sub {

    lives_ok {
        $impl->phenotype_set_to_tsv_file( {
                input_ref => $test_ws . "/test_phenotype_set"
            } )
    }
    'export phenotypes as tsv';

    lives_ok {
        $impl->phenotype_simulation_set_to_excel_file( {
                input_ref => $test_ws . "/test_phenotype_simset"
            } )
    }
    'phenosim to excel';

    lives_ok {
        $impl->phenotype_simulation_set_to_tsv_file( {
                input_ref => $test_ws . "/test_phenotype_simset"
            } )
    }
    'phenosim to tsv';

};

subtest 'export models' => sub {
    lives_ok {
        $impl->export_model_as_excel_file( {
                input_ref => $test_ws . "/test_model"
            } )
    }
    'export model as excel';

    lives_ok {
        $impl->export_model_as_tsv_file( {
                input_ref => $test_ws . "/test_model"
            } )
    }
    'export model as tsv';

    lives_ok {
        $impl->export_model_as_sbml_file( {
                input_ref => $test_ws . "/test_model"
            } )
    }
    'export model as sbml';

};

subtest 'export FBA' => sub {

    lives_ok {
        $impl->export_fba_as_excel_file( {
                input_ref => $test_ws . "/test_minimal_fba"
            } )
    }
    'export fba as excel';

    lives_ok {
        $impl->export_fba_as_tsv_file( {
                input_ref => $test_ws . "/test_minimal_fba"
            } )
    }
    'export fba as tsv';
};

subtest 'export media' => sub {
    lives_ok {
        $impl->export_media_as_excel_file( {
                input_ref => "KBaseMedia/Carbon-D-Glucose"
            } )
    }
    'export media as excel';

    lives_ok {
        $impl->export_media_as_tsv_file( {
                input_ref => "KBaseMedia/Carbon-D-Glucose"
            } )
    }
    'export media as tsv';
};

subtest 'export phenotype_set and phenotype_simulation_sets' => sub {

    lives_ok {
        $impl->export_phenotype_set_as_tsv_file( {
                input_ref => $test_ws . "/test_phenotype_set"
            } )
    }
    'export phenotypes as tsv';

    lives_ok {
        $impl->export_phenotype_simulation_set_as_excel_file( {
                input_ref => $test_ws . "/test_phenotype_simset"
            } )
    }
    'export phenotypes sim set as excel';

    lives_ok {
        $impl->export_phenotype_set_as_tsv_file( {
                input_ref => $test_ws . "/test_phenotype_simset"
            } )
    }
    'export phenotype sim set as tsv';

};

subtest 'bulk export objects' => sub {

    lives_ok {
        $impl->bulk_export_objects( {
                refs => [ $test_ws . "/test_model", $test_ws . "/test_propagated_model" ],
                workspace        => $test_ws,
                report_workspace => $test_ws,
                all_media        => 1,
                media_format     => "excel"
            } )
    }
    'bulk export of modeling objects';

};


done_testing;
