process NORMALISE {

    input:
    path estimates
    path mosdepth_files, stageAs: 'mosdepth/*'
    path repeats
    path normalise_script

    output:
    path "estimates_normalised.tsv", emit: results

    script:
    """
    Rscript ${normalise_script} ${estimates} mosdepth ${repeats} estimates_normalised.tsv \
        ${params.norm_neighbours} ${params.norm_depth_min} ${params.norm_depth_max} ${params.norm_exclude_region}
    """
}
