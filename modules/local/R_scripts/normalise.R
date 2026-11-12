# Normalise VNTR copy number estimates against samples with similar
# exome-wide coverage profiles, based on Mukamel et al. 2021 (Science).

library(data.table)

args <- commandArgs(trailingOnly = TRUE)
estimates_file <- args[1]               # estimates.tsv from COPY_NUMBER
mosdepth_dir   <- args[2]               # folder with <sample>.regions.bed.gz
repeats_file   <- args[3]               # UCSC simpleRepeat table
out_file       <- args[4]
k              <- as.integer(args[5])   # number of neighbours
depth_lo       <- as.numeric(args[6])   # keep windows with mean depth in [lo, hi]
depth_hi       <- as.numeric(args[7])
exclude_region <- args[8]               # region around the gene, e.g. chr6:159530000-161666000

n_sub    <- 200    # samples used to choose windows
top_frac <- 0.10   # keep the most variable windows (batch-informative)

# read .gz without needing R.utils
read_gz <- function(f, ...) fread(cmd = paste("gzip -dc", shQuote(f)), ...)

region <- regmatches(exclude_region, regexec("^([^:]+):([0-9]+)-([0-9]+)$", exclude_region))[[1]]
if (length(region) != 4) stop("exclude region must look like chr6:159530000-161666000, got: ", exclude_region)
region_chr   <- region[2]
region_start <- as.numeric(region[3])
region_end   <- as.numeric(region[4])

## ---------------- match samples ----------------
files <- list.files(mosdepth_dir, pattern = "\\.regions\\.bed\\.gz$", full.names = TRUE)
names(files) <- sub("\\.regions\\.bed\\.gz$", "", basename(files))

est <- fread(estimates_file)
n_mosdepth <- length(files)
n_est      <- nrow(est)

ids   <- intersect(est$sample, names(files))
files <- files[ids]
est   <- est[match(ids, sample)]
message(length(ids), " samples with both mosdepth output and estimate ",
        "(mosdepth: ", n_mosdepth, ", estimates: ", n_est, ")")
if (length(ids) <= k) {
  stop("need more than ", k, " samples with both mosdepth output and estimate, found ", length(ids),
       ". Lower --norm_neighbours or check that mosdepth files are named <sample>.regions.bed.gz")
}

## ---------------- choose windows ----------------
set.seed(1)
sub_files <- sample(files, min(n_sub, length(files)))

win <- read_gz(sub_files[1], col.names = c("chr", "start", "end", "depth"))[, depth := NULL]
sum_depth <- numeric(nrow(win))
for (f in sub_files) sum_depth <- sum_depth + read_gz(f, select = 4)[[1]]
win[, mean_depth := sum_depth / length(sub_files)]

# 1. autosomes only
win[, keep := chr %in% paste0("chr", 1:22)]

# 2. coverage range
win[mean_depth < depth_lo | mean_depth > depth_hi, keep := FALSE]

# 3. tandem repeats (UCSC simpleRepeat: columns 2-4 = chrom, start, end)
rep <- read_gz(repeats_file, select = 2:4, col.names = c("chr", "start", "end"))
setkey(rep, chr, start, end)
hit <- foverlaps(win[, .(chr, start, end, idx = .I)], rep, nomatch = 0L)
win[unique(hit$idx), keep := FALSE]

# 4. region around the gene
win[chr == region_chr & end > region_start & start < region_end, keep := FALSE]

keep_idx <- which(win$keep)
message(length(keep_idx), " windows kept")
if (length(keep_idx) == 0) stop("no windows kept, check --norm_depth_min and --norm_depth_max")

## ---------------- load kept windows for all samples ----------------
M <- matrix(NA_real_, nrow = length(keep_idx), ncol = length(files),
            dimnames = list(NULL, names(files)))
n_win <- nrow(win)
for (j in seq_along(files)) {
  d <- read_gz(files[j], select = 4)[[1]]
  if (length(d) != n_win) stop("window mismatch in ", files[j], ": ", length(d), " vs ", n_win, " windows")
  M[, j] <- d[keep_idx]
  if (j %% 250 == 0) message("loaded ", j, " / ", length(files))
}

## ---------------- coverage barcodes + neighbours ----------------
# each sample to the same mean depth
M <- sweep(M, 2, colMeans(M), "/") * mean(M)

# each window: centre and scale by Poisson SD
mu <- rowMeans(M)
Z  <- (M - mu) / sqrt(mu)
rm(M); invisible(gc())

# rescale so the median window has SD 1, keep most variable windows, crop
sds <- sqrt(rowMeans(Z^2))
Z   <- Z / median(sds)
sds <- sds / median(sds)
Z   <- Z[sds >= quantile(sds, 1 - top_frac), , drop = FALSE]
Z   <- pmin(pmax(Z, -2), 2)
message(nrow(Z), " batch-informative windows used for distances")

# distances between samples and k nearest neighbours
D <- as.matrix(dist(t(Z)))
diag(D) <- Inf
nb <- t(apply(D, 1, function(d) order(d)[1:k]))

## ---------------- normalise ----------------
est[, cne_norm := cne_vntr / sapply(seq_len(.N), function(i) mean(cne_vntr[nb[i, ]], na.rm = TRUE))]

fwrite(est, out_file, sep = "\t")
message("written: ", out_file)
