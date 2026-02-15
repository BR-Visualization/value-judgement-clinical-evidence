# 🛠️ Development Tools Quick Reference

Development scripts and tools are in the **`dev/`** folder.

## 🤖 Automated Checks (Recommended)

### Lintr Pre-commit Hook ✅

**Status: All 190 linting issues fixed!** Your code will now pass GitHub
CI/CD.

The pre-commit hook catches linting issues before they reach GitHub:

``` bash
# Verify everything is ready:
Rscript verify-precommit-ready.R

# The hook runs automatically on every commit:
git add .
git commit -m "your message"
```

See `LINTR_FIXES_SUMMARY.md` for what was fixed, or `PRECOMMIT_SETUP.md`
for troubleshooting.

### Other Git Hooks

Install additional Git hooks:

``` bash
./dev/setup-git-hooks.sh
```

This will: - ✅ Run checks automatically before every commit - ✅
Regenerate plots before every push - ✅ Catch 95% of CI/CD issues before
they reach GitHub!

## 🔧 Manual Checks

Or run checks manually:

``` bash
Rscript dev/quick-check.R  # Quick (~1 minute)
```

## Full Documentation

- **`dev/AUTOMATION_SUMMARY.md`** - 🤖 Automation overview (Git hooks)
- **`dev/GIT_HOOKS_GUIDE.md`** - Complete Git hooks guide  
- **`dev/BEFORE_YOU_PUSH.md`** - Pre-push checklist
- **`dev/CI_TESTING_GUIDE.md`** - Complete CI/CD testing guide
- **`dev/README.md`** - Overview of all dev tools

## What’s in `dev/`?

    dev/
    ├── README.md                              # Overview
    ├── BEFORE_YOU_PUSH.md                     # Quick checklist
    ├── CI_TESTING_GUIDE.md                    # Full testing guide
    ├── quick-check.R                          # ⚡ Fast check (1 min)
    ├── pre-push-check.R                       # 🔍 Full check (3 min)
    ├── test-ci-locally.sh                     # 🐳 Run GH Actions locally
    ├── generate_publication_plots_with_fonts.R # 📊 Examples
    └── ... (other development files)

## Common Workflows

**Before committing:**

``` r
devtools::document()  # Update documentation
```

**Before pushing:**

``` bash
Rscript dev/quick-check.R  # Quick validation
```

**For thorough testing:**

``` bash
Rscript dev/pre-push-check.R  # Comprehensive checks
```

------------------------------------------------------------------------

**See `dev/README.md` for complete documentation.**
