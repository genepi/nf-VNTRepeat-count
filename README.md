# nf-VNTRepeat-count: A pipeline to estimate VNTR repeat count from short-read sequencing data

## About
This repository includes an automated DSL2 Nextflow pipeline to estimate the total number of repeats of a VNTR (large variable number tandem repeat) from sequencing data in BAM format and additionally providing the respective realigned BAM files from the vntr-calling-nf pipeline (https://github.com/genepi/vntr-calling-nf/tree/publish-realign-fastq-output).

The pipeline has been applied to the **KIV-2 VNTR** of the **LPA gene** but may also be used for **other similar VNTRs** in the future.


## Quick Start

1) Install [Nextflow](https://www.nextflow.io/docs/latest/getstarted.html#installation) (nextflow=25.10.0)
2) Clone the repository from GitHub, move into the repository folder and check that you're on the branch of the repository that you want to run
3) Run the pipeline on a test dataset

```
nextflow run main.nf -profile test,<docker,singularity>
```

3) Run the pipeline on your data

```
nextflow run main.nf -c <nextflow.config> -profile <docker,singularity>
```

## Parameters
### Required Parameters
| Tables       | Value                                                     | Description                                                                                                                                          |
| ------------ | --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| bam_dir      | Path of the directory of the bam files from the sequencing data       | Directory of bam files from sequencing data (e.g. WES or WGS). Note: pipeline takes all bam files in this directory as input                         |
| bam_dir_vntr | Path of the directory of the realigned bam files from vntr-calling nf | Directory of realigend bam files for the VNTR of interest as given by vntr-calling-nf. Note: pipeline takes all bam files in this directory as input |


### Additional Parameters
| Tables           | Value                                                                                   | Description                                                                  |
| ---------------- | --------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| build            | hg38 or hg19                                                                            | For now not working, not implemented yet so it only works with hg38 so far   |
| exons_coord      | bed file with the coordinates of the nonrepetitive exons to take for calculation (hg38) | Default nonrepetitive exon 1 and 2 of the LPA gene (assets/lpa_nonrep_exons) |
| vntr_exons_coord | bed file with the coordinates of the repetitive exons to take for calculation (hg38)    | Default repetitive exon 1 and 2 of the LPA gene (assets/lpa_kiv2_exons)      |

## Output

The pipeline gives out two folders (coverage and formula). The estimated copy number of the analyzed VNTR (cne_vntr) is given in the file formula/estimates.tsv.

## Example for a nextflow.config

```
/*

========================================================================================

Nextflow config file for running minimal tests

========================================================================================

Defines input files and everything required to run a fast and simple pipeline test.

----------------------------------------------------------------------------------------

*/

  

params {

bam_dir = "test-data/bam"

bam_dir_vntr = "test-data/realigned"

}
```


## License
The pipeline is MIT Licensed.
