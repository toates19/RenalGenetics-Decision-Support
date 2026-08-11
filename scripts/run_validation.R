#!/usr/bin/env Rscript
# scripts/run_validation.R
# -----------------------------------------------------------------------------
# Command-line entry point for the validation batch scorer.
#
#   Rscript scripts/run_validation.R [input.xlsx] [output_prefix]
#
# Defaults to RenalGenetics_Validation_Template.xlsx and writes
# <prefix>_results.csv plus <prefix>_summary.txt next to it.
#
# Run from the repository root so the data/ and R/ paths resolve.
# -----------------------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
infile <- if (length(args) >= 1) args[1] else "RenalGenetics_Validation_Template.xlsx"
prefix <- if (length(args) >= 2) args[2] else "validation"

if (!file.exists("data/bayes_params.R"))
  stop("run this from the repository root (data/bayes_params.R not found)")
if (!file.exists(infile))
  stop("input file not found: ", infile)

suppressWarnings({
  source("data/bayes_params.R")
  source("data/panels.R")
  source("data/strict_criteria.R")
  source("R/bayes.R")
  source("R/eligibility.R")
  source("R/batch_score.R")
})

cat("RenalGenetics batch validation scorer\n")
cat("input: ", infile, "\n\n", sep = "")

# A silently-dead modifier would corrupt the study, so check before scoring.
problems <- check_harness_fidelity(verbose = TRUE)
cat("\n")

res <- batch_score_file(infile)
summ <- summarise_validation(res)

results_csv <- paste0(prefix, "_results.csv")
summary_txt <- paste0(prefix, "_summary.txt")

write.csv(res, results_csv, row.names = FALSE)

con <- file(summary_txt, open = "wt")
sink(con); sink(con, type = "message")
cat("RenalGenetics validation run\n")
cat("input: ", infile, "\n")
cat("rows scored: ", nrow(res), "\n")
if (length(problems)) {
  cat("\nFIDELITY PROBLEMS (results may be affected):\n")
  for (p in problems) cat("  - ", p, "\n", sep = "")
}
print(summ)
if (any(nzchar(res$warnings))) {
  cat("\nExtraction warnings by patient\n")
  cat(strrep("-", 62), "\n")
  w <- res[nzchar(res$warnings), c("Patient_ID", "warnings")]
  for (i in seq_len(nrow(w))) cat(sprintf("  %-10s %s\n", w$Patient_ID[i], w$warnings[i]))
}
sink(type = "message"); sink(); close(con)

print(summ)
cat("written: ", results_csv, "\n", sep = "")
cat("written: ", summary_txt, "\n", sep = "")
