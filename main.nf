nextflow.enable.dsl=2

include { COVERAGE } from './modules/local/coverage.nf'
include { COPY_NUMBER } from './modules/local/copy_number.nf'
include { MOSDEPTH } from './modules/local/mosdepth.nf'
include { NORMALISE } from './modules/local/normalise.nf'


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

    COPY_NUMBER(coverage_summary_ch, 
                file("${projectDir}/modules/local/R_scripts/copy_number.R"))

    normalised_ch = Channel.empty()
    mosdepth_ch   = Channel.empty()
    if (params.normalise.toString().toBoolean()) {
        if (params.mosdepth_dir) {
            // reuse mosdepth output from an earlier run
            regions_ch = Channel.fromPath("${params.mosdepth_dir}/*.regions.bed.gz", checkIfExists: true)
        } else {
            bam_idx_ch = bam_ch.map { bam ->
                def bai = [file("${bam}.bai"), file("${bam.parent}/${bam.baseName}.bai")].find { it.exists() }
                if (!bai) {
                    error "No index found for ${bam}. mosdepth needs ${bam.name}.bai or ${bam.baseName}.bai next to the BAM file"
                }
                tuple(bam, bai)
            }
            MOSDEPTH(bam_idx_ch)
            regions_ch  = MOSDEPTH.out.regions
            mosdepth_ch = MOSDEPTH.out.regions
        }

        NORMALISE(COPY_NUMBER.out.results,
                  regions_ch.collect(),
                  file(params.repeats_file, checkIfExists: true),
                  file("${projectDir}/modules/local/R_scripts/normalise.R"))
        normalised_ch = NORMALISE.out.results
    }

    publish:
    coverage = coverage_summary_ch
    estimates = COPY_NUMBER.out.results
    normalised = normalised_ch
    mosdepth = mosdepth_ch
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

    normalised {
        path 'estimates'
        mode 'copy'
    }

    mosdepth {
        path 'mosdepth'
        mode 'copy'
    }
}
