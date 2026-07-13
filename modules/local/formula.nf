process FORMULA {
   // conda "${moduleDir}/environment.yml" todo: figure out whether it is needed or recommended once we have built a docker image

    input:
    path coverage_summary

    output:
    path "estimates.tsv", emit: results

    script:
    """
    Rscript ${moduleDir}/R_scripts/formula.R ${coverage_summary} estimates.tsv
    """
}
