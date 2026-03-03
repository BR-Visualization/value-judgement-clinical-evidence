#!/usr/bin/env Rscript
# Verification script - Run this before committing to ensure everything passes

cat("🔍 Pre-commit Verification\n")
cat(strrep("=", 70), "\n\n")

# Check 1: lintr package
cat("1. Checking lintr package... ")
if (!requireNamespace("lintr", quietly = TRUE)) {
  cat("❌ FAIL\n")
  cat("   Install with: install.packages('lintr')\n")
  quit(save = "no", status = 1)
}
cat("✅ OK\n")

# Check 2: Pre-commit hook exists
cat("2. Checking pre-commit hook... ")
hook_path <- ".git/hooks/pre-commit"
if (!file.exists(hook_path)) {
  cat("❌ FAIL\n")
  cat("   Hook not found at:", hook_path, "\n")
  quit(save = "no", status = 1)
}
cat("✅ OK\n")

# Check 3: .lintr config
cat("3. Checking .lintr configuration... ")
if (!file.exists(".lintr")) {
  cat("❌ FAIL\n")
  cat("   .lintr file not found\n")
  quit(save = "no", status = 1)
}
lintr_config <- readLines(".lintr")
if (any(grepl("line_length_linter\\(100\\)", lintr_config))) {
  cat("✅ OK (100 char limit)\n")
} else {
  cat("⚠️  Warning: line_length_linter(100) not found\n")
}

# Check 4: zzz_globals.R exists
cat("4. Checking global variables... ")
if (!file.exists("R/zzz_globals.R")) {
  cat("❌ FAIL\n")
  cat("   R/zzz_globals.R not found\n")
  quit(save = "no", status = 1)
}
cat("✅ OK\n")

# Check 5: Run lintr
cat("5. Running lintr::lint_package()... ")
lints <- lintr::lint_package()

if (length(lints) == 0) {
  cat("✅ PASS\n")
} else {
  cat("❌ FAIL\n")
  cat("\n", length(lints), "linting issue(s) found:\n")
  cat(strrep("-", 70), "\n")
  for (i in seq_len(min(10, length(lints)))) {
    lint <- lints[[i]]
    cat(sprintf("%s:%d - %s\n",
                basename(lint$filename),
                lint$line_number,
                substr(lint$message, 1, 60)))
  }
  if (length(lints) > 10) {
    cat("... and", length(lints) - 10, "more\n")
  }
  cat(strrep("-", 70), "\n")
  quit(save = "no", status = 1)
}

# All checks passed
cat("\n")
cat(strrep("=", 70), "\n")
cat("🎉 ALL CHECKS PASSED!\n")
cat(strrep("=", 70), "\n")
cat("\n")
cat("Your code is ready to commit:\n")
cat("  git add .\n")
cat("  git commit -m 'Your commit message'\n")
cat("\n")
cat("The pre-commit hook will run automatically and should pass.\n")
cat("GitHub CI/CD lint checks will also pass.\n")
cat("\n")
