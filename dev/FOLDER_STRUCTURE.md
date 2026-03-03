# Package Folder Structure

## Overview

```
brpubVJCE/
├── .github/workflows/           # CI/CD workflows (GitHub Actions)
├── R/                          # Package R code
├── man/                        # Documentation (auto-generated)
├── inst/                       # Installed files (data, images)
├── tests/                      # Unit tests
├── vignettes/                  # Long-form documentation
├── data/                       # Package data
├── dev/                        # 📁 Development tools (YOU ARE HERE)
├── DESCRIPTION                 # Package metadata
├── NAMESPACE                   # Exported functions (auto-generated)
├── DEV_TOOLS.md               # Quick reference to dev/ folder
└── README.md                   # Package overview
```

## The `dev/` Folder

**Purpose:** Development-only files that help with package maintenance but aren't part of the package itself.

**Contents:**
- ✅ CI/CD testing scripts
- ✅ Documentation and proposals
- ✅ Example/demo scripts
- ✅ Development notes
- ✅ Benchmark scripts
- ✅ Internal tools

**Key Feature:** Excluded from package builds via `.Rbuildignore`

## Why This Structure?

### ✅ Benefits

1. **Clean package builds** - Dev files don't bloat the package
2. **Version controlled** - All dev tools tracked in git
3. **Team collaboration** - Everyone has access to the same tools
4. **Standard practice** - Follows R package conventions
5. **Easy discovery** - All dev tools in one place

### 📦 What Gets Built vs What Doesn't

**Included in package build:**
- R/ (code)
- man/ (documentation)
- data/ (datasets)
- inst/ (installed files)
- tests/ (unit tests)
- vignettes/ (tutorials)
- DESCRIPTION, NAMESPACE, LICENSE

**Excluded from package build:**
- dev/ (development tools)
- .github/ (CI/CD configs)
- .Rproj.user/ (RStudio files)
- README.Rmd (source, README.md is included)
- Various config files (.lintr, .gitignore, etc.)

## Comparison with Other Approaches

### ❌ Root Directory (Old Approach)
```
brpubVJCE/
├── generate_publication_plots.R     # ❌ Clutters root
├── pre-push-check.R                # ❌ Clutters root
├── FONT_SCALING_PROPOSAL.md        # ❌ Clutters root
└── ... (package files)
```

Problems:
- Root directory gets cluttered
- Hard to distinguish package files from dev files
- R CMD check complains about non-standard files

### ✅ dev/ Folder (Current Approach)
```
brpubVJCE/
├── dev/                            # ✅ All dev files here
│   ├── generate_publication_plots.R
│   ├── pre-push-check.R
│   └── FONT_SCALING_PROPOSAL.md
├── DEV_TOOLS.md                    # ✅ Quick reference
└── ... (standard package files)
```

Benefits:
- Clean root directory
- Clear separation of concerns
- No R CMD check notes about non-standard files
- Easy to find dev tools

### 🗂️ inst/ Folder (Alternative)
```
brpubVJCE/
└── inst/
    └── dev/                        # Alternative location
```

Why we didn't use this:
- inst/ gets installed with the package
- Would bloat package installation size
- Users don't need dev tools

## R Package Conventions

The `dev/` folder follows established R package development practices:

1. **usethis package** - Encourages `dev/` for development scripts
2. **golem package** - Uses `dev/` for Shiny app development tools
3. **pkgdown** - Recognizes `dev/` as development-only

## Adding New Files

### When to add to `dev/`:
- ✅ CI/CD testing scripts
- ✅ Data generation scripts
- ✅ Benchmarking code
- ✅ Internal documentation
- ✅ Example/demo scripts
- ✅ Development proposals

### When NOT to add to `dev/`:
- ❌ Package R code → goes in `R/`
- ❌ User documentation → goes in `vignettes/`
- ❌ Package data → goes in `data/`
- ❌ Tests → goes in `tests/`
- ❌ Installed resources → goes in `inst/`

## Related Files

### .Rbuildignore
Lists patterns of files to exclude from package builds:
```
^dev$           # Excludes dev/ folder
^DEV_TOOLS\.md$ # Excludes dev tools guide
```

### .gitignore
Lists files to exclude from git (but these ARE excluded):
```
.Rproj.user/
.Rhistory
.RData
```

## References

- [R Packages book - "Other components"](https://r-pkgs.org/other-components.html)
- [usethis::use_devtools()](https://usethis.r-lib.org/)
- [Writing R Extensions - Package structure](https://cran.r-project.org/doc/manuals/r-release/R-exts.html#Package-structure)
