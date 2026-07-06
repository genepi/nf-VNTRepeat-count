nextflow.enable.dsl=2

include { COVERAGE } from './modules/local/coverage.nf'

workflow {
    main:
    exons_nonrep_ch      = Channel.fromPath(params.exons_coord)
    bam_ch      = Channel.fromPath("${params.bam_dir}/*.bam")

    vntr_exons_coord_ch = Channel.fromPath(params.vntr_exons_coord)
    bam_vntr_ch = Channel.fromPath("${params.bam_dir_vntr}/*.bam")

    pairs_ch      = bam_ch.combine(exons_nonrep_ch)
    pairs_vntr_ch = bam_vntr_ch.combine(vntr_exons_coord_ch)

    all_pairs_ch = pairs_ch.mix(pairs_vntr_ch)

    COVERAGE(all_pairs_ch)
    
    coverage_summary = COVERAGE.out.row
        .collectFile(name: params.output_file_coverage, seed: "BAM\tBED\tSUM\n", newLine: false)

    publish:
    coverage = coverage_summary
}

output {
    coverage {
        path 'coverage'
        mode 'copy'
    }
}
