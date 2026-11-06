nextflow.enable.dsl=2

include { COVERAGE } from './modules/local/coverage.nf'
include { FORMULA } from './modules/local/formula.nf'


workflow {
    main:
    nonrep_bed_ch      = Channel.fromPath(params.nonrep_bed, checkIfExists: true)
    bam_ch      = Channel.fromPath("${params.bam_dir}/*.bam", checkIfExists: true)

    vntr_bed_ch = Channel.fromPath(params.vntr_bed, checkIfExists: true)
    bam_vntr_ch = Channel.fromPath("${params.bam_dir_vntr}/*.bam", checkIfExists: true)

    pairs_ch      = bam_ch.combine(nonrep_bed_ch).map { bam, bed -> tuple('nonrep', bam, bed) }
    pairs_vntr_ch = bam_vntr_ch.combine(vntr_bed_ch).map { bam, bed -> tuple('vntr', bam, bed) }

    all_pairs_ch = pairs_ch.mix(pairs_vntr_ch)

    COVERAGE(all_pairs_ch)
    
    coverage_summary_ch = COVERAGE.out.row
        .collectFile(name: 'coverage_summary.tsv', seed: "BAM\tBED\tTYPE\tMEAN\n", newLine: false, sort: { it.name })

    FORMULA(coverage_summary_ch, 
            file("${projectDir}/modules/local/R_scripts/formula.R"))

    publish:
    coverage = coverage_summary_ch
    estimates = FORMULA.out.results
}

output {
    coverage {
        enabled params.save_coverage.toString().toBoolean()
        path 'coverage'
        mode 'copy'
    }

    estimates {
        path 'estimates'
        mode 'copy'
    }
}
