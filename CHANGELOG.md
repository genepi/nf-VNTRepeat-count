# Changelog

## v1.0.0 - 2026-11-07

- Rename `--exons_coord` to `--nonrep_bed` and `--vntr_exons_coord` to `--vntr_bed`. The old names are ignored, so update existing commands and configs.
- Fail at startup if the BAM directories or BED files do not exist.
- Remove `--output_file_coverage`. The coverage summary is always named `coverage_summary.tsv`.
