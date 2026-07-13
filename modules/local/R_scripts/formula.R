library(dplyr)
library(tidyr)
library(stringr)

args <- commandArgs(trailingOnly = TRUE)
coverage_summary <- args[1]
output_estimates <- args[2]

estimates <- read.table(coverage_summary, header = TRUE, sep = "\t", stringsAsFactors = FALSE)

estimates <- estimates %>%
  mutate(
    exome = as.numeric(str_extract(BAM, "\\d+"))
  )

estimates <- estimates %>%
  pivot_wider(
    id_cols = exome,
    names_from = BED,
    values_from = SUM
  )

estimates <- estimates %>%
  rename(
    exons1_sum = `exons1.bed`,
    exons2_sum = `exons2.bed`,
    kiv2_1 = `kiv2-1.bed`,
    kiv2_2 = `kiv2-2.bed`,
    proband = `exome`
  )

estimates <- estimates %>%
  dplyr::mutate(
    cne_kiv2_1 = ifelse(!is.na(exons1_sum), kiv2_1 / (1/8 * exons1_sum), NA),
    cne_kiv2_2 = ifelse(!is.na(exons2_sum), kiv2_2 / (1/8 * exons2_sum), NA),
    cne_kiv2 = 1/2 * (cne_kiv2_1 + cne_kiv2_2)
  )

# Relative difference tells you how big the difference is compared to the size of the numbers.
# Quite relaxed to just filter extremes: keeps rows where kiv2_1 and kiv2_2 differ by 99.9% or less relative to their average.
rel_threshold <- 0.999
estimates <- estimates %>%
  filter(abs(kiv2_1 - kiv2_2) / ((kiv2_1 + kiv2_2) / 2) <= rel_threshold)

write.table(estimates, output_estimates, sep = "\t", quote = FALSE, row.names = FALSE)
