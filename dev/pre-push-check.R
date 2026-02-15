#!/usr/bin/env Rscript
# Pre-push checks to simulate CI/CD workflows locally
# Run this before pushing to GitHub to catch issues early

cat("\n")
cat("========================================\n")
cat("Pre-Push CI/CD Checks for brpubVJCE\n")
cat("========================================\n\n")

# Track overall success
all_passed <- TRUE

# Helper function to run checks
run_check <- function(name, func) {
  cat("------------------------------------------\n")
  cat(sprintf("Running: %s\n", name))
  cat("------------------------------------------\n")
  
  result <- tryCatch({
    func()
    TRUE
  }, error = function(e) {
    cat(sprintf("❌ ERROR: %s\n", e$message))
    FALSE
  })
  
  if (result) {
    cat(sprintf("✅ %s PASSED\n\n", name))
  } else {
    cat(sprintf("❌ %s FAILED\n\n", name))
  }
  
  return(result)
}

# 1. R CMD check (most important - this is what GitHub Actions runs)
cat("\n🔍 CHECK 1: R CMD check\n")
check1 <- run_check("R CMD check", function() {
  check_results <- devtools::check(
    document = FALSE,
    args = c("--no-manual", "--as-cran"),
    error_on = "warning"
  )
  
  # Print summary
  cat("\nCheck Results:\n")
  cat(sprintf("  Errors:   %d\n", length(check_results$errors)))
  cat(sprintf("  Warnings: %d\n", length(check_results$warnings)))
  cat(sprintf("  Notes:    %d\n", length(check_results$notes)))
  
  # Fail if there are errors or warnings
  if (length(check_results$errors) > 0 || length(check_results$warnings) > 0) {
    stop("R CMD check found errors or warnings")
  }
  
  invisible(TRUE)
})
all_passed <- all_passed && check1

# 2. Documentation check
cat("\n📝 CHECK 2: Documentation\n")
check2 <- run_check("Documentation", function() {
  devtools::document()
  
  # Check if any files were modified
  status <- system("git status --porcelain man/ NAMESPACE", intern = TRUE)
  if (length(status) > 0) {
    cat("⚠️  WARNING: Documentation files were updated. You should commit these changes:\n")
    cat(paste(status, collapse = "\n"), "\n")
    return(invisible(TRUE))  # Don't fail, just warn
  }
  
  cat("✓ Documentation is up to date\n")
  invisible(TRUE)
})
all_passed <- all_passed && check2

# 3. Code style check (styler)
cat("\n🎨 CHECK 3: Code Style\n")
check3 <- run_check("Code Style", function() {
  if (!requireNamespace("styler", quietly = TRUE)) {
    cat("ℹ️  Skipping style check (styler not installed)\n")
    cat("   Install with: install.packages('styler')\n")
    return(invisible(TRUE))
  }
  
  # Check if files need styling
  files_need_styling <- styler::style_pkg(dry = "on")
  
  if (length(files_need_styling$changed) > 0) {
    cat("⚠️  WARNING: The following files need styling:\n")
    cat(paste("  -", files_need_styling$changed, collapse = "\n"), "\n")
    cat("\n  Run: styler::style_pkg() to fix\n")
    return(invisible(TRUE))  # Don't fail, just warn
  }
  
  cat("✓ Code style is good\n")
  invisible(TRUE)
})
all_passed <- all_passed && check3

# 4. Linting check
cat("\n🔍 CHECK 4: Linting\n")
check4 <- run_check("Linting", function() {
  if (!requireNamespace("lintr", quietly = TRUE)) {
    cat("ℹ️  Skipping lint check (lintr not installed)\n")
    cat("   Install with: install.packages('lintr')\n")
    return(invisible(TRUE))
  }
  
  # Lint the package
  lint_results <- lintr::lint_package()
  
  if (length(lint_results) > 0) {
    cat(sprintf("⚠️  Found %d lint issues:\n", length(lint_results)))
    print(lint_results)
    cat("\n  Review these issues before pushing\n")
    return(invisible(TRUE))  # Don't fail, just warn
  }
  
  cat("✓ No lint issues found\n")
  invisible(TRUE)
})
all_passed <- all_passed && check4

# 5. Test coverage check
cat("\n🧪 CHECK 5: Tests\n")
check5 <- run_check("Tests", function() {
  test_results <- devtools::test()
  
  cat("\nTest Results:\n")
  cat(sprintf("  Passed:  %d\n", sum(test_results$passed)))
  cat(sprintf("  Failed:  %d\n", sum(test_results$failed)))
  cat(sprintf("  Skipped: %d\n", sum(test_results$skipped)))
  cat(sprintf("  Warnings: %d\n", sum(test_results$warning)))
  
  if (sum(test_results$failed) > 0) {
    stop("Some tests failed")
  }
  
  invisible(TRUE)
})
all_passed <- all_passed && check5

# 6. Build check
cat("\n📦 CHECK 6: Package Build\n")
check6 <- run_check("Package Build", function() {
  pkg_file <- devtools::build(quiet = FALSE)
  cat(sprintf("✓ Package built successfully: %s\n", basename(pkg_file)))
  invisible(TRUE)
})
all_passed <- all_passed && check6

# Summary
cat("\n")
cat("==========================================\n")
cat("SUMMARY\n")
cat("==========================================\n")

if (all_passed) {
  cat("✅ ALL CHECKS PASSED!\n")
  cat("   Your package is ready to push to GitHub.\n")
  quit(status = 0)
} else {
  cat("❌ SOME CHECKS FAILED\n")
  cat("   Please fix the issues above before pushing.\n")
  quit(status = 1)
}
