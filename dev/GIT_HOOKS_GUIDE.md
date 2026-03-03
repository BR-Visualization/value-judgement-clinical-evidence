# Git Hooks Guide for brpubVJCE

Git hooks automatically run scripts at key points in your Git workflow. This ensures code quality and prevents issues before they reach GitHub.

## Quick Setup

```bash
# Run the interactive installer
./dev/setup-git-hooks.sh
```

Or manually install:
```bash
# Copy hooks to .git/hooks/
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/pre-push
```

## What Gets Automated

### Pre-Commit Hook (Runs on `git commit`)

**What it does:**
1. ✅ Updates documentation (`devtools::document()`)
2. ✅ Runs quick R CMD check (errors & warnings only)
3. ✅ Auto-stages updated documentation files

**Time:** ~30 seconds

**Example:**
```bash
git add R/my_function.R
git commit -m "Update function"

# Hook runs automatically:
🔍 Pre-commit check...
✅ Documentation updated
✅ Checks passed
```

### Pre-Push Hook (Runs on `git push`)

**What it does:**
1. ✅ Runs full R CMD check (`--as-cran`)
2. ✅ Regenerates publication plots
3. ✅ Renders README.md (if README.Rmd changed)
4. ✅ Checks for TODO/FIXME comments
5. ✅ Offers to stage updated plots

**Time:** ~2-3 minutes

**Example:**
```bash
git push origin main

# Hook runs automatically:
🚀 Pre-push check...
1️⃣ Running R CMD check...
   Errors:   0
   Warnings: 0
   Notes:    2
✅ R CMD check passed

2️⃣ Regenerating publication plots...
✅ Plots generated successfully
📊 Plot files updated

⚠️  IMPORTANT: New plots generated!
Stage plots and amend commit? (y/n) y
✅ Plots staged and commit amended

✅ All checks passed!
```

## Bypassing Hooks

Sometimes you need to skip hooks (use sparingly!):

```bash
# Skip pre-commit hook
git commit --no-verify -m "WIP: work in progress"

# Skip pre-push hook
git push --no-verify
```

**When to skip:**
- Work in progress commits
- Emergency hotfixes
- When you know the issue and will fix it later
- When hooks are failing due to unrelated issues

**⚠️  Warning:** Skipping hooks means CI/CD might fail on GitHub!

## Hook Locations

Hooks are stored in:
```
.git/hooks/
├── pre-commit     # Runs before each commit
└── pre-push       # Runs before each push
```

**Note:** `.git/` folder is not tracked by Git, so hooks must be installed on each machine.

## Customizing Hooks

### Make Pre-Commit Faster

Edit `.git/hooks/pre-commit` to skip checks:

```bash
#!/bin/bash
# Minimal pre-commit: just update docs
Rscript -e "devtools::document()" > /dev/null 2>&1
git diff --name-only man/ NAMESPACE | grep -q . && git add man/ NAMESPACE
exit 0
```

### Add Custom Checks

Add to `.git/hooks/pre-push`:

```bash
# Add code style check
echo "Checking code style..."
Rscript -e "styler::style_pkg()" || exit 1

# Add test coverage check
echo "Checking test coverage..."
Rscript -e "cov <- covr::package_coverage(); if (cov < 80) quit(status=1)" || exit 1
```

## Troubleshooting

### Hook doesn't run

**Check if executable:**
```bash
ls -la .git/hooks/pre-commit
# Should show: -rwxr-xr-x (executable)
```

**Make executable:**
```bash
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/pre-push
```

### Hook runs but fails

**See full error:**
```bash
# Run the hook manually
.git/hooks/pre-commit
# or
.git/hooks/pre-push
```

**Common issues:**
- Package dependencies missing
- R not in PATH
- devtools not installed

### Hook is too slow

**Option 1: Make it faster**
- Remove plot regeneration from pre-commit
- Use `--no-tests` flag for R CMD check
- Only run on changed files

**Option 2: Move to pre-push only**
```bash
# Remove pre-commit hook
rm .git/hooks/pre-commit

# Keep only pre-push hook
# This runs less frequently
```

**Option 3: Run manually**
```bash
# Instead of automatic hooks, run manually:
Rscript dev/quick-check.R
```

## Team Collaboration

### Sharing Hooks

Since `.git/hooks/` is not tracked by Git, share hooks via:

1. **setup-git-hooks.sh script** (recommended)
   ```bash
   # Each team member runs:
   ./dev/setup-git-hooks.sh
   ```

2. **Git hook templates**
   ```bash
   # Store in dev/hooks/
   dev/hooks/pre-commit
   dev/hooks/pre-push
   
   # Install with:
   cp dev/hooks/* .git/hooks/
   chmod +x .git/hooks/*
   ```

3. **Document in README**
   ```markdown
   ## Setup
   After cloning, install Git hooks:
   ./dev/setup-git-hooks.sh
   ```

### Hook Standards

**For teams, decide:**
- [ ] Which hooks are required vs optional?
- [ ] Can developers bypass hooks?
- [ ] What checks are mandatory?
- [ ] How to handle slow hooks?

## Advanced: Git Hook Templates

Set up hooks automatically for all new repos:

```bash
# Create global hook template directory
mkdir -p ~/.git-templates/hooks

# Copy your hooks
cp .git/hooks/pre-commit ~/.git-templates/hooks/
cp .git/hooks/pre-push ~/.git-templates/hooks/

# Configure Git to use templates
git config --global init.templatedir '~/.git-templates'

# Now all new repos will have these hooks!
```

## Comparison with CI/CD

| Aspect | Git Hooks (Local) | GitHub Actions (CI/CD) |
|--------|------------------|------------------------|
| **When** | Before commit/push | After push |
| **Where** | Your machine | GitHub servers |
| **Speed** | Fast (local) | Slower (remote) |
| **Feedback** | Immediate | Delayed (minutes) |
| **Platform** | Your OS only | Multiple OS/R versions |
| **Bypass** | Easy (--no-verify) | Hard (need admin) |
| **Best for** | Catching obvious errors | Comprehensive testing |

**Best Practice:** Use both!
- ✅ Local hooks catch simple issues fast
- ✅ CI/CD catches platform-specific issues
- ✅ Together = robust quality control

## Available Hooks

Git supports many hooks. We use:

- ✅ **pre-commit** - Before commit is created
- ✅ **pre-push** - Before push to remote
- ❌ **post-commit** - After commit (not used)
- ❌ **post-merge** - After merge (not used)
- ❌ **pre-rebase** - Before rebase (not used)

See: `man githooks` or https://git-scm.com/docs/githooks

## Examples

### Example 1: Simple Pre-Commit (Fast)
```bash
#!/bin/bash
# Only update docs, no checks
Rscript -e "devtools::document()" > /dev/null 2>&1
exit 0
```

### Example 2: Comprehensive Pre-Push
```bash
#!/bin/bash
# Run all checks and regenerate everything
Rscript dev/pre-push-check.R || exit 1
Rscript dev/regenerate-plots.R || exit 1
exit 0
```

### Example 3: Interactive Pre-Push
```bash
#!/bin/bash
# Ask before regenerating plots
echo "Regenerate plots? (y/n)"
read -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    Rscript dev/regenerate-plots.R
fi
exit 0
```

## Resources

- [Git Hooks Documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
- [Husky (Node.js hook manager)](https://typicode.github.io/husky/)
- [pre-commit framework](https://pre-commit.com/)
- [R Packages book - Git](https://r-pkgs.org/software-development-practices.html#git)

## Summary

✅ **Do:**
- Install hooks on your development machine
- Use hooks to catch simple errors early
- Document hooks for team members
- Keep hooks fast (<1 minute for pre-commit)

❌ **Don't:**
- Rely solely on hooks (still need CI/CD)
- Make hooks too strict (frustrates developers)
- Forget to share hooks with team
- Skip hooks without good reason
