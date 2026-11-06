
library(dplyr)
library(tidyr)
library(stringr)

args <- commandArgs(trailingOnly = TRUE)
coverage_summary <- args[1]
output_estimates <- args[2]

estimates <- read.table(coverage_summary, header = TRUE, sep = "\t", stringsAsFactors = FALSE)

nonrep_beds <- sort(unique(estimates$BED[estimates$TYPE == "nonrep"]))
vntr_beds <- sort(unique(estimates$BED[estimates$TYPE == "vntr"]))

estimates <- estimates %>%
  mutate(
    sample = str_extract(BAM, "^[^.]+")
  )

estimates <- estimates %>%
  pivot_wider(
    id_cols = sample,
    names_from = BED,
    values_from = MEAN
  ) %>%
  select(sample, all_of(c(nonrep_beds, vntr_beds))) %>%
  arrange(sample)





  estimates <- estimates %>%
  dplyr::mutate(
    nonrep_mean = rowMeans(dplyr::select(., dplyr::all_of(nonrep_beds)), na.rm = TRUE),
    vntr_mean = rowMeans(dplyr::select(., dplyr::all_of(vntr_beds)), na.rm = TRUE),
    cne_vntr = ifelse(!is.na(nonrep_mean) & nonrep_mean != 0, vntr_mean / nonrep_mean, NA)
  )



write.table(estimates, output_estimates, sep = "\t", quote = FALSE, row.names = FALSE)
