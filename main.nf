
include { NEXTFLOW_RUN as NFCORE_TAXPROFILER   } from "$projectDir/modules/local/nextflow/run/main"
include { NEXTFLOW_RUN as GMS_METAVAL          } from "$projectDir/modules/local/nextflow/run/main"
include { readWithDefault                      } from "$projectDir/functions/local/utils"
include { resolveFileFromDir as getSamplesheet } from "$projectDir/functions/local/utils"

workflow {

    // Initialize undefined channels
    def taxprofiler_output_samplesheet      = null
    def taxprofiler_output                  = null


    // Run pipelines
    // TAXPROFILER
    NFCORE_TAXPROFILER (
        'nf-core/taxprofiler',
        "${ params.general.wf_opts?: ''} ${params.taxprofiler.wf_opts?: ''}",     // workflow opts
        readWithDefault( params.taxprofiler.params_file, Channel.value([]) ),     // params file
        readWithDefault( params.taxprofiler.input, Channel.value([]) ), // samplesheet
        readWithDefault( params.taxprofiler.add_config, Channel.value([]) ),      // custom config
        workflow.workDir.resolve('nf-core/taxprofiler').toUriString(),
    )
    taxprofiler_output                  = NFCORE_TAXPROFILER.out.output
    taxprofiler_output_samplesheet      = getSamplesheet( 'downstream_samplesheets/metaval.csv', NFCORE_TAXPROFILER.out.output )

    // METAVAL
    GMS_METAVAL (
        'genomic-medicine-sweden/metaval',
        "${ params.general.wf_opts?: ''} ${params.metaval.wf_opts?: ''}",               // workflow opts
        readWithDefault( params.metaval.params_file, Channel.value([]) ),               // params file
        readWithDefault( params.metaval.input, taxprofiler_output_samplesheet),         // input
        readWithDefault( params.metaval.add_config, Channel.value([]) ),                // custom config
        workflow.workDir.resolve('genomic-medicine-sweden/metaval').toUriString(),
    )
}
