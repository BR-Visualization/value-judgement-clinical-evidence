# ✅ Pre-Push Checklist

**Use this checklist before pushing to GitHub to avoid CI/CD failures!**

## Quick Check (2 minutes)

```bash
# In terminal
Rscript quick-check.R
```

Or in R:
```r
devtools::check(args = c("--no-manual", "--as-cran"))
```

**What it checks:**
- ✅ Package builds without errors
- ✅ All examples run
- ✅ All tests pass  
- ✅ Documentation is valid
- ✅ No critical warnings

## Current Package Status

**Latest Check Results:**
- ✅ 0 Errors
- ✅ 0 Warnings
- ✅ 2 Notes (acceptable)

Your package is **READY TO PUSH** ✨

## Common Pre-Push Tasks

### 1. Update Documentation
```r
devtools::document()
```

### 2. Format Code (Optional)
```r
styler::style_pkg()
```

### 3. Run Tests
```r
devtools::test()
```

### 4. Build Package
```r
devtools::build()
```

### 5. Final Check
```r
devtools::check(args = c("--as-cran"))
```

## What Happens After Push?

Your GitHub Actions will automatically run:

1. **R-CMD-check** - Tests on macOS, Windows, Ubuntu (multiple R versions)
2. **Lint** - Code quality checks
3. **Style** - Code formatting checks
4. **Test Coverage** - How much code is tested
5. **pkgdown** - Builds documentation website

## If CI Fails

1. Check the GitHub Actions tab in your repo
2. Look at the failed workflow logs
3. Fix the issues locally
4. Re-run `Rscript quick-check.R` to verify fix
5. Push again

## Pro Tips

✅ **Run checks locally first** - Saves time debugging on CI  
✅ **Commit documentation changes** - Run `devtools::document()` before committing  
✅ **Test on multiple platforms** - Use `devtools::check()` with `--as-cran`  
✅ **Keep dependencies minimal** - Only import what you need  
✅ **Write good tests** - They catch bugs early  

## Need More Help?

See `CI_TESTING_GUIDE.md` for detailed instructions on:
- Using `act` to run actual GitHub Actions locally
- Comprehensive pre-push checks
- Troubleshooting common CI/CD issues
- Understanding each workflow

---

**Last Updated:** ${date}
**Package Version:** 0.0.1
**Status:** ✅ Ready for CI/CD
