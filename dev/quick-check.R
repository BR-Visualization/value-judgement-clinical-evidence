#!/usr/bin/env Rscript
# Quick pre-push check - focuses on the most critical CI/CD checks

cat("🚀 Running quick pre-push checks...\n\n")

# 1. The most important check - R CMD check (what CI/CD runs)
cat("1️⃣  R CMD check (--as-cran)...\n")
devtools::check(
  document = FALSE,
  args = c("--no-manual", "--as-cran"),
  error_on = "warning",
  quiet = FALSE
)

cat("\n✅ All checks passed! Safe to push to GitHub.\n")
