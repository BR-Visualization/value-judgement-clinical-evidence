#!/usr/bin/env Rscript
# Test script to verify the pre-commit lintr hook is working

cat("Testing lintr pre-commit hook setup...\n\n")

# Check if lintr is installed
if (!requireNamespace("lintr", quietly = TRUE)) {
  cat("❌ lintr is not installed\n")
  cat("   Install with: install.packages('lintr')\n")
  quit(save = "no", status = 1)
}
cat("✅ lintr package is installed\n")

# Check if hook file exists
hook_path <- file.path(".git", "hooks", "pre-commit")
if (!file.exists(hook_path)) {
  cat("❌ Pre-commit hook not found at:", hook_path, "\n")
  quit(save = "no", status = 1)
}
cat("✅ Pre-commit hook file exists\n")

# Check if hook is executable (Unix-like systems)
if (.Platform$OS.type == "unix") {
  info <- file.info(hook_path)
  if (is.na(info$mode)) {
    cat("⚠️  Cannot check if hook is executable\n")
  } else {
    # Check if owner has execute permission
    is_executable <- bitwAnd(info$mode, as.octmode("100")) > 0
    if (is_executable) {
      cat("✅ Hook is executable\n")
    } else {
      cat("❌ Hook is not executable\n")
      cat("   Run: chmod +x .git/hooks/pre-commit\n")
      quit(save = "no", status = 1)
    }
  }
}

# Run lintr to see current status
cat("\nRunning lintr::lint_package() to check current code...\n")
cat(strrep("-", 60), "\n")

lints <- lintr::lint_package()

cat(strrep("-", 60), "\n")

if (length(lints) > 0) {
  cat("\n⚠️  Found", length(lints), "linting issue(s)\n")
  cat("   The pre-commit hook will block commits until these are fixed.\n")
  cat("   Run lintr::lint_package() to see details.\n")
} else {
  cat("\n✅ No linting issues found!\n")
  cat("   Your code is ready to commit.\n")
}

cat("\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
cat("Pre-commit hook setup is complete and ready to use!\n")
cat("\n")
cat("Next time you commit, lintr will run automatically:\n")
cat("  git add <files>\n")
cat("  git commit -m 'your message'  # lintr runs here\n")
cat("\n")
cat("To bypass the check (not recommended):\n")
cat("  git commit --no-verify -m 'your message'\n")
cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
