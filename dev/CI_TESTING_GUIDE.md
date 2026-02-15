# CI/CD Testing Guide

This guide explains how to test your GitHub Actions workflows locally before pushing to GitHub, helping you catch issues early and avoid CI/CD failures.

## Quick Start (Recommended)

### Option 1: Simple R CMD Check (Fastest)

This runs the same check that GitHub Actions runs:

```r
# In R console
devtools::check(args = c("--no-manual", "--as-cran"))
```

Or use the provided script:

```bash
Rscript quick-check.R
```

### Option 2: Comprehensive Pre-Push Check

This runs multiple checks similar to your CI/CD workflows:

```bash
Rscript pre-push-check.R
```

This checks:
1. ✅ R CMD check (errors & warnings)
2. ✅ Documentation is up to date
3. ✅ Code style (styler)
4. ✅ Linting (lintr)
5. ✅ Tests pass
6. ✅ Package builds

## Advanced: Using `act` to Run Actual GitHub Actions

If you want to run the *exact* GitHub Actions workflows locally using Docker:

### Installation

**macOS:**
```bash
brew install act
```

**Linux:**
```bash
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

**Windows:**
```bash
choco install act-cli
```

### Usage

**Run all workflows:**
```bash
./test-ci-locally.sh
```

**Run specific workflow:**
```bash
# R CMD check (most important)
act -W .github/workflows/R-CMD-check.yaml

# Lint
act -W .github/workflows/lint.yaml

# Style
act -W .github/workflows/style.yaml

# Test coverage
act -W .github/workflows/test-coverage.yaml
```

**For M1/M2 Macs:**
```bash
act -W .github/workflows/R-CMD-check.yaml \
  --container-architecture linux/amd64 \
  -P ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest
```

## What Each Workflow Checks

### R-CMD-check.yaml (Critical)
- Runs on: macOS, Windows, Ubuntu (multiple R versions)
- Checks: Package builds, examples run, tests pass, documentation complete
- **This is the most important one to pass**

### lint.yaml
- Checks: Code quality with lintr
- Looks for: Common coding issues, style violations

### style.yaml  
- Checks: Code formatting with styler
- Ensures: Consistent code style

### test-coverage.yaml
- Checks: Test coverage
- Reports: How much of your code is tested

### document.yaml
- Checks: Documentation is up to date
- Runs: `devtools::document()`

### pkgdown.yaml
- Builds: Package website
- Creates: Documentation site

## Common CI/CD Issues and Solutions

### Issue: "checking Rd \\usage sections ... WARNING"
**Solution:** Run `devtools::document()` and commit the changes

### Issue: "Non-ASCII characters in data"
**Solution:** Use `tools::showNonASCII()` to find and fix non-ASCII characters

### Issue: "Undocumented arguments"
**Solution:** Add `@param` documentation for all function parameters

### Issue: "Examples fail"
**Solution:** Test examples with `devtools::run_examples()`

### Issue: "Tests fail on Ubuntu but pass on macOS"
**Solution:** Use `devtools::check()` with `--as-cran` flag locally

## Best Practice Workflow

Before every push to GitHub:

```bash
# 1. Update documentation
Rscript -e "devtools::document()"

# 2. Run quick check
Rscript quick-check.R

# 3. If time permits, run comprehensive check
Rscript pre-push-check.R

# 4. Commit and push
git add .
git commit -m "Your commit message"
git push
```

## Continuous Integration Matrix

Your package is tested on:

| OS | R Version | Purpose |
|---|---|---|
| macOS-latest | release | Mac users |
| Windows-latest | release | Windows users |
| Ubuntu-latest | devel | Upcoming R version |
| Ubuntu-latest | release | Most common setup |
| Ubuntu-latest | oldrel-1 | R from ~1 year ago |

## Useful Commands

```r
# Check package
devtools::check()

# Check with CRAN settings
devtools::check(args = c("--as-cran"))

# Update documentation
devtools::document()

# Run tests
devtools::test()

# Check code style
styler::style_pkg()

# Lint code
lintr::lint_package()

# Build package
devtools::build()

# Check test coverage
covr::package_coverage()
```

## GitHub Actions Secrets

If your workflows need secrets (API keys, tokens):

1. Go to: Settings → Secrets and variables → Actions
2. Add secrets as needed
3. Reference in workflows: `${{ secrets.SECRET_NAME }}`

## Troubleshooting

**act fails with "Error: Cannot connect to Docker"**
- Make sure Docker Desktop is running
- On macOS: `open -a Docker`

**R CMD check passes locally but fails on CI**
- Try with `--as-cran` flag: `devtools::check(args = "--as-cran")`
- Check if you're using platform-specific code

**Memory issues on CI**
- Reduce example data sizes
- Use `\dontrun{}` for memory-intensive examples

## Resources

- [R Packages book](https://r-pkgs.org/)
- [GitHub Actions for R](https://github.com/r-lib/actions)
- [act documentation](https://github.com/nektos/act)
- [devtools documentation](https://devtools.r-lib.org/)
