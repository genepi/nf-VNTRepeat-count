# nf-VNTRepeat-count

A Nextflow pipeline that estimates the copy number of a VNTR (variable number tandem repeat) from read coverage. It compares the mean coverage of the repeated exons with the mean coverage of the gene's non-repetitive exons.

It can be used for any gene with a VNTR, as long as the exon coordinates are known and the BAM files are available. The defaults are set up for the KIV-2 repeat in *LPA*. See [Using another gene](#using-another-gene).

## How it works

1. **COVERAGE** runs `bedtools coverage` for every BAM and BED combination and takes the mean across the regions in each BED file.
2. **FORMULA** matches the two BAM files of each sample and calculates `cne_vntr = vntr_mean / nonrep_mean`.

## Requirements

- [Nextflow](https://www.nextflow.io/docs/latest/install.html) 25.10.0 or later, which you can install with [Micromamba](https://mamba.readthedocs.io/en/latest/installation/micromamba-installation.html) as shown below.
- [Docker](https://docs.docker.com/get-docker/) or [Singularity](https://docs.sylabs.io/guides/latest/user-guide/). The containers are downloaded automatically on the first run.

## Quick start

Install Nextflow and nf-test in their own environment:

```bash
micromamba create -y -n nextflow -c conda-forge -c bioconda "nextflow>=25.10.0" nf-test
micromamba activate nextflow
```

Clone the repository and run the included test data. Run this from the repository root, because the test paths are relative to it.

```bash
git clone https://github.com/genepi/nf-VNTRepeat-count.git
cd nf-VNTRepeat-count
nextflow run main.nf -profile test,docker
```

To use Singularity, replace `docker` with `singularity`.

## Running on your own data

You need two directories of BAM files:

| Directory | Contents |
| --- | --- |
| `--bam_dir` | Original BAM files, aligned to hg38 for the default *LPA* coordinates |
| `--bam_dir_vntr` | The same samples realigned to the VNTR reference. For the default KIV-2 coordinates, the contig is `KIV2_6` |

The pipeline does not do the realignment yet, so you need to create these BAM files first with the [vntr-calling-nf](https://github.com/genepi/vntr-calling-nf) pipeline.

```bash
nextflow run main.nf -profile docker \
    --bam_dir /path/to/bams \
    --bam_dir_vntr /path/to/realigned_bams
```

### BAM file names

Samples are matched by the part of the file name before the first dot, so both BAM files of a sample must start with the same name, such as `NA12718.final.bam` and `NA12718.realigned.bam`.

Only files ending in `.bam` directly inside each directory are used. CRAM files are not picked up.

## Parameters

| Parameter | Description | Default |
| --- | --- | --- |
| `--bam_dir` | Directory with the original BAM files | Required |
| `--bam_dir_vntr` | Directory with the realigned BAM files | Required |
| `--exons_coord` | BED files for the non-repetitive exons | `assets/lpa_nonrep_exons/nonrep-exon-{1,2}.bed` |
| `--vntr_exons_coord` | BED files for the VNTR exons, in VNTR reference coordinates | `assets/lpa_kiv2_exons/vntr-exon-{1,2}.bed` |
| `--output_file_coverage` | Name of the coverage summary file | `coverage_summary.tsv` |

### Using another gene

The pipeline works for any gene if you have the coordinates of its repeated and non-repetitive exons, plus BAM files covering the gene and BAM files realigned to the VNTR reference.

Pass your own BED files with a quoted glob. The file names must start with `nonrep` and `vntr`, because that prefix is how the formula step groups the columns.

```bash
nextflow run main.nf -profile docker \
    --bam_dir /path/to/bams \
    --bam_dir_vntr /path/to/realigned_bams \
    --exons_coord '/path/to/beds/nonrep-*.bed' \
    --vntr_exons_coord '/path/to/beds/vntr-*.bed'
```

## Output

Results are written to `results/`:

| File | Contents |
| --- | --- |
| `results/coverage/coverage_summary.tsv` | One row per BAM and BED combination, with the columns `BAM`, `BED` and `MEAN` |
| `results/formula/estimates.tsv` | One row per sample |

`estimates.tsv` contains these columns:

| Column | Description |
| --- | --- |
| `sample` | Sample name taken from the BAM file name |
| One column per BED file, such as `vntr-exon-1.bed` | Mean coverage for that BED file |
| `nonrep_mean` | Mean of the `nonrep*` columns |
| `vntr_mean` | Mean of the `vntr*` columns |
| `cne_vntr` | Estimated VNTR copy number, `vntr_mean / nonrep_mean`. `NA` if `nonrep_mean` is missing or 0 |

## Running tests

The module tests use [nf-test](https://www.nf-test.com/), which is included in the environment from the [quick start](#quick-start):

```bash
nf-test test
```

## License

See [LICENSE](LICENSE).
