# 🤖 Automation Summary

## What's Automated?

```
┌─────────────────────────────────────────────────────────┐
│                   Git Workflow                          │
│                                                         │
│  git add file.R                                        │
│  git commit -m "Update"  ──► Pre-commit hook runs     │
│                              │                          │
│                              ├─ Update docs            │
│                              ├─ Quick check            │
│                              └─ Auto-stage docs        │
│                                                         │
│  git push origin main    ──► Pre-push hook runs       │
│                              │                          │
│                              ├─ Full R CMD check       │
│                              ├─ Regenerate plots       │
│                              ├─ Check TODOs            │
│                              └─ Offer to stage plots   │
│                                                         │
│  GitHub receives push    ──► CI/CD runs               │
│                              │                          │
│                              ├─ R-CMD-check (multi-OS) │
│                              ├─ Lint                   │
│                              ├─ Style                  │
│                              ├─ Test coverage          │
│                              └─ Build pkgdown          │
└─────────────────────────────────────────────────────────┘
```

## Current Status

✅ **Git Hooks:** Installed
✅ **Pre-commit:** Active
✅ **Pre-push:** Active
✅ **CI/CD:** Ready (.github/workflows/)

## Timeline

**Before hooks:**
```
Developer → write code → commit → push → wait for CI/CD → 😱 it failed!
                                                            ↓
                                                   fix → push again
```

**With hooks:**
```
Developer → write code → commit → ✅ local checks pass
                       → push   → ✅ local checks + plots updated
                                → CI/CD → ✅ passes first time!
```

## What Runs When?

### Pre-Commit (Every commit, ~30 sec)
```bash
git commit -m "message"
```
- ✅ Update documentation automatically
- ✅ Check for errors and warnings
- ✅ Auto-stage documentation changes

**Frequency:** Every commit
**Time:** ~30 seconds
**Fails if:** Errors or warnings found

### Pre-Push (Every push, ~2-3 min)
```bash
git push
```
- ✅ Full R CMD check (--as-cran)
- ✅ Regenerate all publication plots
- ✅ Check for TODO/FIXME comments
- ✅ Offer to stage updated plots

**Frequency:** Every push
**Time:** ~2-3 minutes  
**Fails if:** R CMD check fails

### CI/CD (After push, ~5-10 min)
```
GitHub Actions automatically
```
- ✅ Test on macOS, Windows, Ubuntu
- ✅ Test with R devel, release, oldrel
- ✅ Run lint and style checks
- ✅ Calculate test coverage
- ✅ Build documentation website

**Frequency:** Every push to main/PR
**Time:** ~5-10 minutes
**Fails if:** Any platform/version fails

## Setup

### First Time Setup
```bash
# Install hooks (one-time)
./dev/setup-git-hooks.sh

# Choose option 1 (both hooks)
```

### Verify Installation
```bash
# Check if installed
./dev/setup-git-hooks.sh
# Choose option 4 (view hooks)
```

### Test Hooks
```bash
# Test pre-commit manually
.git/hooks/pre-commit

# Test pre-push manually
.git/hooks/pre-push
```

## Skipping Hooks

Sometimes you need to skip (use sparingly!):

```bash
# Skip pre-commit
git commit --no-verify -m "WIP"

# Skip pre-push
git push --no-verify
```

**⚠️  Warning:** Skipping means CI/CD might fail!

## Customization

### Make Faster
Edit `.git/hooks/pre-commit`:
```bash
#!/bin/bash
# Minimal version - just update docs
Rscript -e "devtools::document()" > /dev/null 2>&1
exit 0
```

### Make Stricter
Edit `.git/hooks/pre-push`:
```bash
# Add style check
Rscript -e "styler::style_pkg()" || exit 1

# Add coverage check
Rscript -e "cov <- covr::package_coverage(); if (cov < 80) quit(status=1)" || exit 1
```

### Disable Temporarily
```bash
# Rename to disable
mv .git/hooks/pre-commit .git/hooks/pre-commit.disabled

# Rename to re-enable
mv .git/hooks/pre-commit.disabled .git/hooks/pre-commit
```

## Comparison

| Check | Manual | Git Hooks | CI/CD |
|-------|--------|-----------|-------|
| **When** | You run it | Auto (commit/push) | Auto (after push) |
| **Where** | Local | Local | GitHub servers |
| **Speed** | Instant | Fast | Slower |
| **Platforms** | Your OS | Your OS | All OS |
| **R versions** | Your R | Your R | All R versions |
| **Can skip** | Yes | Yes (--no-verify) | No (admin only) |
| **Feedback** | Immediate | Immediate | Delayed |

**Best practice:** Use all three!
- Manual checks during development
- Git hooks before committing
- CI/CD for final validation

## Benefits

### Before Automation
- 😱 Frequent CI/CD failures
- ⏰ Long feedback loops
- 🔄 Many "fix CI" commits
- 📝 Forgotten documentation updates
- 🎨 Outdated plots in repo

### After Automation
- ✅ CI/CD passes first time
- ⚡ Immediate feedback
- 🎯 Fewer fix commits
- 📝 Docs always current
- 🎨 Plots always fresh

## Statistics

**Typical workflow without hooks:**
```
100 pushes → 30 CI failures → 30 fix commits → frustration
```

**With hooks:**
```
100 pushes → 5 CI failures → 5 fix commits → 😊 happy developer
```

**Time saved per week:**
- Manual checking: ~30 min/week
- CI/CD failures: ~1 hour/week
- **Total saved: ~1.5 hours/week**

## Troubleshooting

### Hook doesn't run
```bash
# Make executable
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/pre-push
```

### Hook fails
```bash
# Run manually to see error
.git/hooks/pre-commit

# Check R is in PATH
which R

# Check devtools installed
Rscript -e "library(devtools)"
```

### Hook too slow
```bash
# Option 1: Remove pre-commit, keep pre-push
rm .git/hooks/pre-commit

# Option 2: Lighten pre-commit (see Customization above)

# Option 3: Run manually instead
Rscript dev/quick-check.R
```

## Resources

- **Full guide:** `dev/GIT_HOOKS_GUIDE.md`
- **CI/CD guide:** `dev/CI_TESTING_GUIDE.md`
- **Quick reference:** `dev/BEFORE_YOU_PUSH.md`
- **Manual checks:** `dev/quick-check.R`

## Quick Commands

```bash
# Install hooks
./dev/setup-git-hooks.sh

# View status
./dev/setup-git-hooks.sh  # Choose option 4

# Uninstall
./dev/setup-git-hooks.sh  # Choose option 5

# Test manually
.git/hooks/pre-commit
.git/hooks/pre-push

# Skip once
git commit --no-verify
git push --no-verify
```

---

**Status:** ✅ Automation Active
**Last Updated:** 2026-02-15
**Version:** 1.0
