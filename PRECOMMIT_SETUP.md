# Pre-commit Lintr Hook Setup

This document explains how to set up a pre-commit hook to run lintr
checks locally before code reaches GitHub CI/CD.

## Why Use Pre-commit Hooks?

Pre-commit hooks catch linting issues **before** you commit, preventing
failed CI/CD builds and reducing the feedback loop.

## Setup Instructions

### Step 1: Ensure lintr is installed

``` r
install.packages("lintr")
```

### Step 2: Make the hook executable

The hook file is already created at `.git/hooks/pre-commit`. On Windows,
you may need to ensure Git can execute it.

**On Windows:** - Git Bash should work automatically - If you have
issues, you can use the PowerShell version instead

**On macOS/Linux:**

``` bash
chmod +x .git/hooks/pre-commit
```

Or run in R:

``` r
system("chmod +x .git/hooks/pre-commit")
```

### Step 3: Test the hook

Try making a commit. The hook will automatically run lintr checks:

``` bash
git add .
git commit -m "test commit"
```

You should see:

    Running lintr checks...
    ✅ All lintr checks passed!

## How It Works

The pre-commit hook runs `lintr::lint_package()` before each commit. If
any linting issues are found: - ❌ The commit is blocked - Issues are
displayed in the console - You can fix the issues and try committing
again

## Bypassing the Hook (Not Recommended)

In rare cases where you need to commit without passing lintr:

``` bash
git commit --no-verify -m "your message"
```

## Hook Versions

Two versions are available:

1.  **`pre-commit`** (default) - Runs `lintr::lint_package()` on the
    entire package
    - More thorough
    - Slower for large projects
2.  **`pre-commit-staged-only`** - Only lints files being committed
    - Faster
    - Less comprehensive
    - To use:
      `mv .git/hooks/pre-commit-staged-only .git/hooks/pre-commit`

## Troubleshooting

### Hook not running

- Verify the file is named exactly `pre-commit` (no extension) in
  `.git/hooks/`
- Check it’s executable: `ls -l .git/hooks/pre-commit`
- Try running manually: `.git/hooks/pre-commit`

### lintr not found

- Install lintr: `install.packages("lintr")`
- Make sure it’s in your default R library path

### Windows-specific issues

- Ensure Git Bash is installed (comes with Git for Windows)
- Alternatively, use the PowerShell version: `.git/hooks/pre-commit.ps1`

## What Lintr Rules Are Applied?

The hook uses your project’s `.lintr` configuration:

``` r
linters: linters_with_defaults(indentation_linter = NULL)
```

This matches what runs in your GitHub Actions CI/CD pipeline.

## Integration with Development Workflow

1.  Write code
2.  Run `lintr::lint_package()` during development to catch issues early
3.  Stage changes: `git add <files>`
4.  Commit: `git commit -m "message"` → hook runs automatically
5.  If lintr passes → commit succeeds → push to GitHub
6.  If lintr fails → fix issues → try again

## Sharing with Team

To ensure all team members use the hook:

1.  Add setup instructions to your `README.md` or `CONTRIBUTING.md`
2.  Consider adding a setup script that team members run once
3.  Note: `.git/hooks/` is not tracked by Git, so each developer must
    set it up locally

Alternatively, consider using the [`pre-commit`
framework](https://pre-commit.com/) for team-wide hook management.
