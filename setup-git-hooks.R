# Setup script to enable pre-commit lintr checks
# Run this script once to set up the git hook

cat("Setting up pre-commit lintr hook...\n")

# Check if lintr is installed
if (!requireNamespace("lintr", quietly = TRUE)) {
  cat("❌ lintr package is not installed.\n")
  cat("   Install it with: install.packages('lintr')\n")
  stop("lintr is required for pre-commit checks")
}

# Path to the hook
hook_path <- file.path(".git", "hooks", "pre-commit")

# Check if hook already exists
if (file.exists(hook_path)) {
  cat("⚠️  A pre-commit hook already exists.\n")
  response <- readline("   Do you want to overwrite it? (yes/no): ")
  if (tolower(trimws(response)) != "yes") {
    cat("Setup cancelled.\n")
    quit(save = "no")
  }
}

# Copy the hook
hook_source <- file.path(".git", "hooks", "pre-commit")
if (file.exists(hook_source)) {
  cat("✅ Pre-commit hook is already in place!\n")
} else {
  cat("❌ Hook file not found. Make sure pre-commit file exists in .git/hooks/\n")
  quit(save = "no", status = 1)
}

# Make the hook executable (Unix-like systems)
if (.Platform$OS.type == "unix") {
  system(paste("chmod +x", shQuote(hook_path)))
  cat("✅ Made hook executable\n")
}

cat("\n")
cat("✅ Setup complete!\n")
cat("\n")
cat("The pre-commit hook will now run lintr checks before each commit.\n")
cat("To bypass the check (not recommended), use: git commit --no-verify\n")
cat("\n")
cat("Test it by running: lintr::lint_package()\n")
