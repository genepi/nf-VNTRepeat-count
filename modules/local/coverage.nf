process COVERAGE {
    tag "${bam.simpleName}_${bed.simpleName}"

    input:
    tuple path(bam), path(bed)

    output:
    path "*.tsv", emit: row

    script:
    """
    SUM=\$(bedtools coverage -a ${bed} -b ${bam} -mean | awk '{sum += \$5} END {print sum+0}')
    echo -e "${bam.name}\t${bed.name}\t\$SUM" > "${bam.simpleName}_${bed.simpleName}.tsv"
    """
}
