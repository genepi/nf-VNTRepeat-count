process FORMULA {
   // conda "${moduleDir}/environment.yml" todo: figure out whether it is needed or recommended once we have built a docker image

    input:
    path coverage_summary
    path formula_script

    output:
    path "estimates.tsv", emit: results

    script:
    """
   Rscript ${formula_script} ${coverage_summary} estimates.tsv
    """
}
