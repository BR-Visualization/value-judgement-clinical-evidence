# Quick Start: Lintr Pre-commit Hook

## ✅ Setup Complete!

Your pre-commit lintr hook is **already installed and ready to use**. It
will automatically run on every commit.

## Current Status

**190 linting issues detected** in your codebase. The pre-commit hook
will prevent commits until these are fixed.

## What Happens Now?

When you try to commit code with linting issues:

``` bash
$ git add .
$ git commit -m "my changes"

Running lintr checks...
❌ Linting failed! Please fix the issues above before committing.
```

The commit will be **blocked** until you fix the issues.

## How to Fix Linting Issues

### See all issues:

``` r
lintr::lint_package()
```

### Fix issues in a specific file:

``` r
lintr::lint("R/your_file.R")
```

### Common lintr fixes:

1.  **Line length** - Keep lines under 80-100 characters
2.  **Trailing whitespace** - Remove spaces at end of lines  
3.  **Object naming** - Use `snake_case` not `camelCase`
4.  **Spacing** - Add spaces around operators: `x <- 1` not `x<-1`
5.  **Commas** - Space after comma: `c(1, 2, 3)` not `c(1,2,3)`

### Auto-fix many issues with styler:

``` r
install.packages("styler")
styler::style_pkg()
```

This will automatically fix spacing, indentation, and many other common
issues.

## Bypass Hook (Emergency Only)

If you absolutely must commit without fixing linting:

``` bash
git commit --no-verify -m "your message"
```

⚠️ **Not recommended** - your CI/CD will still fail on GitHub!

## Workflow

    ┌─────────────────┐
    │  Edit R code    │
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │ Check linting   │
    │ lintr::lint()   │ ← Optional but helpful
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │   git add .     │
    └────────┬────────┘
             │
             ▼
    ┌─────────────────┐
    │  git commit     │ ← Hook runs automatically here
    └────────┬────────┘
             │
        ✅ Pass? ────────────────┐
             │                   │
        ❌ Fail?                 ▼
             │           ┌───────────────┐
             ▼           │  git push     │
      ┌─────────────┐    └───────────────┘
      │ Fix issues  │
      └──────┬──────┘
             │
             └──────────┐
                        ▼
                Back to edit code

## Testing the Hook

Run the test script to verify everything works:

``` r
source("test-lintr-hook.R")
```

## Next Steps

1.  **Fix existing linting issues** (you have 190 to fix)

    ``` r
    # Quick auto-fix for many issues:
    styler::style_pkg()

    # Then check what's left:
    lintr::lint_package()
    ```

2.  **Try a test commit** to see the hook in action

    ``` bash
    git add .
    git commit -m "test"
    ```

3.  **Share with your team** - Each developer needs to set up the hook
    locally

    - Share this document or `PRECOMMIT_SETUP.md`
    - Consider adding to onboarding docs

## Need Help?

- Full documentation: `PRECOMMIT_SETUP.md`
- Test the setup: `Rscript test-lintr-hook.R`
- See current issues: `lintr::lint_package()`
- Auto-fix issues: `styler::style_pkg()`

------------------------------------------------------------------------

**Remember:** The hook uses your `.lintr` config, which matches your
GitHub CI/CD checks. Passing locally = passing on GitHub! 🎉
