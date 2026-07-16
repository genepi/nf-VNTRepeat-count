
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
    values_from = MEAN
  )





  estimates <- estimates %>%
  dplyr::mutate(
    nonrep_mean = rowMeans(dplyr::select(., dplyr::starts_with("nonrep")), na.rm = TRUE),
    vntr_mean = rowMeans(dplyr::select(., dplyr::starts_with("vntr")), na.rm = TRUE),
    cne_vntr = ifelse(!is.na(nonrep_mean) & nonrep_mean != 0, vntr_mean / nonrep_mean, NA)
  )



write.table(estimates, output_estimates, sep = "\t", quote = FALSE, row.names = FALSE)
