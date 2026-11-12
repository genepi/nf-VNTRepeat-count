[![CI Tests](https://github.com/genepi/nf-VNTRepeat-count/actions/workflows/ci-tests.yml/badge.svg)](https://github.com/genepi/nf-VNTRepeat-count/actions/workflows/ci-tests.yml)
[![nf-test](https://img.shields.io/badge/tested_with-nf--test-337ab7.svg)](https://github.com/askimed/nf-test)

# nf-VNTRepeat-count: A pipeline to estimate VNTR repeat count from short-read sequencing data

A DSL2 Nextflow pipeline that estimates the copy number of a VNTR (variable number tandem repeat) from read coverage in WES or WGS data. It compares the mean coverage of the VNTR coordinates with the mean coverage of the gene's non-repetitive coordinates.

The pipeline has been applied to the **KIV-2 VNTR** of the *LPA* gene, which is the default setup. It can be used for any gene with a VNTR, as long as the VNTR coordinates and non-repetitive coordinates are known and the BAM files are available. See [Using another gene](#using-another-gene).

## Requirements

- [Nextflow](https://www.nextflow.io/docs/latest/install.html) 25.10.0 or later, which you can install with [Mamba](https://mamba.readthedocs.io/en/latest/installation/mamba-installation.html) as shown below.
- [Docker](https://docs.docker.com/get-docker/) or [Singularity](https://docs.sylabs.io/guides/latest/user-guide/). The containers are downloaded automatically on the first run.

## Quick start

Install Nextflow and nf-test in their own environment:

```bash
mamba create -y -n nextflow -c conda-forge -c bioconda "nextflow>=25.10.0" nf-test
mamba activate nextflow
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
| `--bam_dir` | Original BAM files, aligned to the same reference as the `--nonrep_bed` coordinates |
| `--bam_dir_vntr` | The same samples realigned to the VNTR reference. For the default KIV-2 coordinates, the contig is `KIV2_6` |

The pipeline does not do the realignment yet, so you need to create these BAM files first with the [vntr-calling-nf](https://github.com/genepi/vntr-calling-nf) pipeline.

```bash
nextflow run main.nf -profile docker \
    --bam_dir /path/to/bams \
    --bam_dir_vntr /path/to/realigned_bams
```

You can also keep the paths in your own config file:

```groovy
// my.config
params {
    bam_dir      = "/path/to/bams"
    bam_dir_vntr = "/path/to/realigned_bams"
}
```

```bash
nextflow run main.nf -c my.config -profile docker
```

### BAM file names

Samples are matched by the part of the file name before the first dot, so both BAM files of a sample must start with the same name, such as `NA12718.final.bam` and `NA12718.realigned.bam`.

All files ending in `.bam` directly inside each directory are used as input. CRAM files are not picked up.

## Parameters

| Parameter | Description | Default |
| --- | --- | --- |
| `--bam_dir` | Directory with the original BAM files | Required |
| `--bam_dir_vntr` | Directory with the realigned BAM files | Required |
| `--nonrep_bed` | BED files with the non-repetitive coordinates, relative to the reference of the `--bam_dir` BAM files | `assets/lpa_nonrep_exons/nonrep-exon-{1,2}.bed` |
| `--vntr_bed` | BED files with the VNTR coordinates, relative to the VNTR reference | `assets/lpa_kiv2_exons/vntr-exon-{1,2}.bed` |
| `--save_coverage` | Also write the coverage summary to `results/coverage/` | `false` |

The default `--nonrep_bed` coordinates are for hg38. For other references, such as hg37, pass your own BED files with `--nonrep_bed`.

### Normalisation

With `--normalise`, the copy number of each sample is divided by the mean copy number of the samples with the most similar genome-wide coverage profile, based on Mukamel et al. 2021 (Science). The result is the `cne_norm` column in `results/estimates/estimates_normalised.tsv`.

The coverage profiles are computed with [mosdepth](https://github.com/brentp/mosdepth) in 1 kb windows from the `--bam_dir` BAM files. These must be whole-exome or whole-genome BAM files, with a `.bai` index next to each one, and there must be more samples than `--norm_neighbours`. The mosdepth output is written to `results/mosdepth/`, and you can reuse it in later runs with `--mosdepth_dir`.

| Parameter | Description | Default |
| --- | --- | --- |
| `--normalise` | Run the normalisation | `false` |
| `--mosdepth_dir` | Folder with `<sample>.regions.bed.gz` from an earlier run. Skips mosdepth | Not set |
| `--repeats_file` | UCSC simpleRepeat table; windows overlapping it are excluded | UCSC hg38 download |
| `--norm_neighbours` | Number of neighbours | `200` |
| `--norm_depth_min`, `--norm_depth_max` | Keep windows with a mean depth in this range. Adjust to your sequencing depth | `30`, `300` |
| `--norm_exclude_region` | Region around the gene, excluded from the windows | `chr6:159530000-161666000` (LPA ±1 Mb, GRCh38) |

### Using another gene

The pipeline works for any gene if you have its VNTR coordinates and non-repetitive coordinates, plus BAM files covering the gene and BAM files realigned to the VNTR reference.

Pass your own BED files with a quoted glob. The files can have any name, as long as each name is used only once across both parameters.

```bash
nextflow run main.nf -profile docker \
    --bam_dir /path/to/bams \
    --bam_dir_vntr /path/to/realigned_bams \
    --nonrep_bed '/path/to/beds/nonrep-*.bed' \
    --vntr_bed '/path/to/beds/vntr-*.bed'
```

## Output

Results are written to `results/`. The estimated copy number of the VNTR is the `cne_vntr` column in `estimates.tsv`.

| File | Contents |
| --- | --- |
| `results/estimates/estimates.tsv` | One row per sample |
| `results/coverage/coverage_summary.tsv` | One row per BAM and BED combination, with the columns `BAM`, `BED`, `TYPE` (`nonrep` or `vntr`) and `MEAN`. Only written with `--save_coverage` |

`estimates.tsv` contains these columns:

| Column | Description |
| --- | --- |
| `sample` | Sample name taken from the BAM file name |
| One column per BED file, such as `vntr-exon-1.bed` | Mean coverage for that BED file |
| `nonrep_mean` | Mean of the columns from `--nonrep_bed` |
| `vntr_mean` | Mean of the columns from `--vntr_bed` |
| `cne_vntr` | Estimated VNTR copy number, `vntr_mean / nonrep_mean`. `NA` if `nonrep_mean` is missing or 0 |

## Running tests

The module tests use [nf-test](https://www.nf-test.com/), which is included in the environment from the [quick start](#quick-start):

```bash
nf-test test
```

## License

The pipeline is MIT licensed. See [LICENSE](LICENSE).
