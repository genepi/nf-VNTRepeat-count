process COVERAGE {
    tag "${bam.simpleName}_${bed.simpleName}"

    input:
    tuple val(type), path(bam), path(bed)

    output:
    path "*.tsv", emit: row

    script:
    """
    set -o pipefail
    MEAN=\$(bedtools coverage -a ${bed} -b ${bam} -mean | awk '{sum += \$5; n++} END {print (n>0 ? sum/n : 0)}')
    echo -e "${bam.name}\t${bed.name}\t${type}\t\$MEAN" > "${bam.simpleName}_${bed.simpleName}.tsv"
    """
}
