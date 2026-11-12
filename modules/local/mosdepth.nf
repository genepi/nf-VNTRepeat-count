process MOSDEPTH {
    tag "${bam.simpleName}"

    input:
    tuple path(bam), path(bai)

    output:
    path "*.regions.bed.gz", emit: regions

    script:
    """
    mosdepth --by 1000 --no-per-base --fast-mode -t ${task.cpus} ${bam.simpleName} ${bam}
    """
}
