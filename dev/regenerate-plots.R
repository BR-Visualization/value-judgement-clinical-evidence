#!/usr/bin/env Rscript
# Regenerate all publication plots
# This script is called automatically by pre-push hook

cat("📊 Regenerating Publication Plots\n")
cat("==================================\n\n")

# Check if we're in the package root
if (!file.exists("DESCRIPTION")) {
  stop("Must run from package root directory")
}

# Load the package
cat("Loading brpubVJCE...\n")
devtools::load_all(quiet = TRUE)

# Track success
plots_generated <- 0
plots_failed <- 0

# Helper to safely generate plots
generate_plot <- function(name, expr) {
  cat(sprintf("  • %s... ", name))
  result <- tryCatch({
    expr
    cat("✅\n")
    plots_generated <<- plots_generated + 1
    TRUE
  }, error = function(e) {
    cat(sprintf("❌ (%s)\n", e$message))
    plots_failed <<- plots_failed + 1
    FALSE
  })
  invisible(result)
}

# Source the main plot generation script
cat("\nGenerating plots...\n")
if (file.exists("dev/generate_publication_plots.R")) {
  source("dev/generate_publication_plots.R", local = TRUE)
  cat("\n✅ All plots generated from generate_publication_plots.R\n")
} else {
  cat("\n⚠️  No plot generation script found\n")
  cat("   Expected: dev/generate_publication_plots.R\n")
}

cat("\n==================================\n")
cat("Plot generation complete!\n")
cat("==================================\n\n")
