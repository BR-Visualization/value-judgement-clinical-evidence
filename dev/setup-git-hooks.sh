#!/bin/bash
# Setup script for Git hooks
# Run this once to install automated checks

echo "🔧 Git Hooks Setup for brpubVJCE"
echo "=================================="
echo ""
echo "This will install Git hooks that automatically:"
echo "  • Pre-commit:  Update docs, run quick checks"
echo "  • Pre-push:    Run full checks, regenerate plots"
echo ""
echo "Options:"
echo "  1) Install both hooks (recommended)"
echo "  2) Install only pre-commit hook (lighter)"
echo "  3) Install only pre-push hook"
echo "  4) View current hooks"
echo "  5) Uninstall hooks"
echo "  6) Exit"
echo ""
read -p "Choose option (1-6): " choice

case $choice in
    1)
        echo ""
        echo "Installing both hooks..."
        
        # Pre-commit hook
        cat > .git/hooks/pre-commit << 'EOFHOOK'
#!/bin/bash
echo ""
echo "🔍 Pre-commit check..."
echo ""

# Update documentation
Rscript -e "devtools::document()" > /dev/null 2>&1
if git diff --name-only man/ NAMESPACE | grep -q .; then
    git add man/ NAMESPACE
    echo "✅ Documentation updated"
fi

# Quick check (errors/warnings only)
Rscript -e "
    check <- devtools::check(document = FALSE, args = c('--no-manual', '--no-tests'), 
                             error_on = 'never', quiet = TRUE)
    if (length(check\$errors) > 0 || length(check\$warnings) > 0) {
        cat('❌ Check failed - use git commit --no-verify to skip\n')
        quit(status = 1)
    }
    cat('✅ Checks passed\n')
" 2>&1 || exit 1

echo ""
exit 0
EOFHOOK
        
        chmod +x .git/hooks/pre-commit
        
        # Pre-push hook
        cat > .git/hooks/pre-push << 'EOFHOOK'
#!/bin/bash
echo ""
echo "🚀 Pre-push check..."
echo ""

# Full R CMD check
echo "Running R CMD check..."
Rscript dev/quick-check.R 2>&1 || exit 1

# Regenerate plots
if [ -f "dev/generate_publication_plots_with_fonts.R" ]; then
    echo ""
    echo "Regenerating plots..."
    Rscript dev/generate_publication_plots_with_fonts.R > /dev/null 2>&1
    
    if git diff --name-only inst/img/ | grep -q .; then
        echo "⚠️  Plots updated but not committed!"
        echo "   Run: git add inst/img/ && git commit --amend --no-edit"
        read -p "   Stage plots now? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git add inst/img/ && git commit --amend --no-edit
        fi
    fi
fi

echo ""
echo "✅ Ready to push!"
exit 0
EOFHOOK
        
        chmod +x .git/hooks/pre-push
        
        echo "✅ Both hooks installed!"
        ;;
        
    2)
        echo ""
        echo "Installing pre-commit hook only..."
        # Same as above, just pre-commit
        cat > .git/hooks/pre-commit << 'EOFHOOK'
#!/bin/bash
echo "🔍 Pre-commit check..."
Rscript -e "devtools::document()" > /dev/null 2>&1
git diff --name-only man/ NAMESPACE | grep -q . && git add man/ NAMESPACE
Rscript -e "check <- devtools::check(document = FALSE, args = c('--no-manual', '--no-tests'), error_on = 'never', quiet = TRUE); if (length(check\$errors) > 0 || length(check\$warnings) > 0) quit(status = 1)" 2>&1 || exit 1
echo "✅ OK"
exit 0
EOFHOOK
        chmod +x .git/hooks/pre-commit
        echo "✅ Pre-commit hook installed!"
        ;;
        
    3)
        echo ""
        echo "Installing pre-push hook only..."
        cat > .git/hooks/pre-push << 'EOFHOOK'
#!/bin/bash
echo "🚀 Pre-push check..."
Rscript dev/quick-check.R 2>&1 || exit 1
[ -f "dev/generate_publication_plots_with_fonts.R" ] && Rscript dev/generate_publication_plots_with_fonts.R > /dev/null 2>&1
echo "✅ OK"
exit 0
EOFHOOK
        chmod +x .git/hooks/pre-push
        echo "✅ Pre-push hook installed!"
        ;;
        
    4)
        echo ""
        echo "Current hooks:"
        echo ""
        for hook in pre-commit pre-push; do
            if [ -f ".git/hooks/$hook" ]; then
                echo "✅ $hook (installed)"
                echo "   Location: .git/hooks/$hook"
            else
                echo "❌ $hook (not installed)"
            fi
        done
        echo ""
        ;;
        
    5)
        echo ""
        read -p "Remove all Git hooks? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -f .git/hooks/pre-commit .git/hooks/pre-push
            echo "✅ Hooks removed"
        fi
        ;;
        
    6)
        echo "Exiting..."
        exit 0
        ;;
        
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "📚 Usage:"
echo "  • Hooks run automatically on commit/push"
echo "  • Skip with: git commit --no-verify"
echo "  •           git push --no-verify"
echo "  • Reinstall: ./dev/setup-git-hooks.sh"
echo ""
