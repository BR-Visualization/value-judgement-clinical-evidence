# Development Tools and Documentation

This folder contains development scripts, tools, and documentation that are not part of the package itself but are useful for package development and maintenance.

## 📋 Contents

### Git Hooks (Automation)

**Setup automated checks:**
- **`setup-git-hooks.sh`** - Interactive installer for Git hooks
  ```bash
  ./dev/setup-git-hooks.sh
  ```
  - Runs checks automatically on commit/push
  - Regenerates plots before pushing
  - Catches issues before GitHub CI/CD

### CI/CD Testing Tools

**Quick validation before pushing:**
- **`quick-check.R`** - Fast R CMD check (~1 minute)
  ```bash
  Rscript dev/quick-check.R
  ```

**Comprehensive testing:**
- **`pre-push-check.R`** - Full validation suite (~3 minutes)
  ```bash
  Rscript dev/pre-push-check.R
  ```

**Plot generation:**
- **`regenerate-plots.R`** - Regenerate all publication plots
  ```bash
  Rscript dev/regenerate-plots.R
  ```

**Advanced GitHub Actions simulation:**
- **`test-ci-locally.sh`** - Run actual workflows with Docker
  ```bash
  ./dev/test-ci-locally.sh
  ```

### Documentation

- **`GIT_HOOKS_GUIDE.md`** - Complete guide to Git hooks automation
- **`BEFORE_YOU_PUSH.md`** - Quick checklist before pushing to GitHub
- **`CI_TESTING_GUIDE.md`** - Complete guide to CI/CD testing
- **`FONT_SCALING_PROPOSAL.md`** - Technical proposal for font scaling implementation
- **`PLOT_REVIEW_REPORT.md`** - Analysis of plotting functions
- **`FOLDER_STRUCTURE.md`** - Package organization explained
- **`CLAUDE.md`** - Development notes and context

### Example Scripts

- **`generate_publication_plots_with_fonts.R`** - Examples using font scaling
- **`generate_publication_plots.R`** - Original plotting examples
- **`verify_tirs_fonts.R`** - Font rendering verification

## 🚀 Quick Start

### Option 1: Automated (Recommended)

Install Git hooks to run checks automatically:
```bash
./dev/setup-git-hooks.sh
```

This will:
- ✅ Run checks before every commit
- ✅ Regenerate plots before every push
- ✅ Catch issues before they reach GitHub

### Option 2: Manual

Before pushing to GitHub:
```bash
# Quick check (recommended)
Rscript dev/quick-check.R

# Or comprehensive check
Rscript dev/pre-push-check.R

# Regenerate plots
Rscript dev/regenerate-plots.R
```

## 📁 Folder Structure

The `dev/` folder follows R package conventions:
- **Not included in the built package** (listed in `.Rbuildignore`)
- Contains development-only tools and documentation
- Similar to `usethis::use_devtools()` convention

## 🔧 Maintaining This Folder

Add new development scripts here:
- CI/CD tools
- Data generation scripts
- Performance benchmarks
- Internal documentation
- Plot generation examples

## 📚 Related Files

Other development files in the package root:
- `.Rbuildignore` - Files to exclude from package build
- `.gitignore` - Files to exclude from git
- `.lintr` - Linting configuration
- `.github/workflows/` - CI/CD workflow definitions

---

**Note:** This folder is excluded from the package build but is tracked in git to help collaborators with development workflows.
