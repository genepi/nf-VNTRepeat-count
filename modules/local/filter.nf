// # Relative difference tells you how big the difference is compared to the size of the numbers.
// # Quite relaxed to just filter extremes: keeps rows where kiv2_1 and kiv2_2 differ by 99.9% or less relative to their average.
rel_threshold <- 0.999
estimates <- estimates %>%
  filter(abs(`vntr-exon-1.bed` - `vntr-exon-2.bed`) / ((`vntr-exon-1.bed` + `vntr-exon-2.bed`) / 2) <= rel_threshold)

write.table(estimates, output_estimates, sep = "\t", quote = FALSE, row.names = FALSE)

//todo adapt to general number of exons and implement in main.nf and nextflow.config