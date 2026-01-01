#!/bin/bash
# ============================================================================
# POST MERGE - Re-prune kernel after upstream merge
# ============================================================================
#
# This script is designed to be run after merging from upstream to re-apply
# the bespoke pruning to any new files added by the merge.
#
# Workflow:
#   1. git fetch upstream
#   2. git merge upstream/master  (resolve conflicts)
#   3. ./scripts/bespoke/post_merge.sh
#
# What it does:
#   1. Handles merge conflicts in removed directories (accepts removal)
#   2. Re-runs the manifest generation
#   3. Prunes newly added files that aren't needed
#   4. Verifies the build
#
# Usage:
#   ./scripts/bespoke/post_merge.sh [--auto]
#
# Options:
#   --auto    Automatically resolve conflicts and prune without prompting
#
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
AUTO_MODE=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
section() { echo -e "\n${CYAN}=== $* ===${NC}"; }

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto)
            AUTO_MODE=1
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--auto]"
            echo ""
            echo "Options:"
            echo "  --auto    Automatically resolve conflicts and prune"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

cd "$KERNEL_DIR"

# Verify we're in kernel source
if [[ ! -f "Makefile" ]] || ! grep -q "VERSION = 6" Makefile; then
    error "Must run from kernel source root"
fi

# Check if we're in a git repo
if ! git rev-parse --git-dir &>/dev/null; then
    error "Not a git repository"
fi

section "POST-MERGE BESPOKE PRUNING"
echo ""

# ============================================================================
# PHASE 1: Check for and resolve merge conflicts
# ============================================================================
section "PHASE 1: Handle Merge Conflicts"

# Check for unresolved conflicts
CONFLICTS=$(git diff --name-only --diff-filter=U 2>/dev/null || true)

if [[ -n "$CONFLICTS" ]]; then
    info "Found unresolved merge conflicts:"
    echo "$CONFLICTS" | head -20
    echo ""

    # Load known removable directories
    REMOVABLE_DIRS=""
    if [[ -f "$KERNEL_DIR/manifest/known_safe_removable.txt" ]]; then
        REMOVABLE_DIRS=$(cat "$KERNEL_DIR/manifest/known_safe_removable.txt")
    fi

    # Check if conflicts are in removed directories
    CONFLICTS_IN_REMOVED=0
    CONFLICTS_IN_KEPT=0

    while IFS= read -r conflict_file; do
        in_removed=0
        for removed_dir in $REMOVABLE_DIRS; do
            if [[ "$conflict_file" == "$removed_dir"* ]]; then
                in_removed=1
                break
            fi
        done

        if [[ $in_removed -eq 1 ]]; then
            CONFLICTS_IN_REMOVED=$((CONFLICTS_IN_REMOVED + 1))
            if [[ "$AUTO_MODE" == "1" ]]; then
                # Accept deletion (our version)
                git rm -f "$conflict_file" 2>/dev/null || true
            fi
        else
            CONFLICTS_IN_KEPT=$((CONFLICTS_IN_KEPT + 1))
        fi
    done <<< "$CONFLICTS"

    info "Conflicts in removed directories: $CONFLICTS_IN_REMOVED"
    info "Conflicts in kept directories: $CONFLICTS_IN_KEPT"

    if [[ $CONFLICTS_IN_KEPT -gt 0 ]]; then
        warn "You have $CONFLICTS_IN_KEPT conflicts in directories that should be kept."
        warn "Please resolve these manually before continuing."

        if [[ "$AUTO_MODE" == "0" ]]; then
            echo ""
            echo "Conflicted files in kept directories:"
            while IFS= read -r conflict_file; do
                in_removed=0
                for removed_dir in $REMOVABLE_DIRS; do
                    if [[ "$conflict_file" == "$removed_dir"* ]]; then
                        in_removed=1
                        break
                    fi
                done
                if [[ $in_removed -eq 0 ]]; then
                    echo "  $conflict_file"
                fi
            done <<< "$CONFLICTS"
            exit 1
        fi
    fi

    if [[ "$AUTO_MODE" == "1" && $CONFLICTS_IN_REMOVED -gt 0 ]]; then
        info "Auto-resolved $CONFLICTS_IN_REMOVED conflicts (accepted deletion)"
    fi
else
    info "No merge conflicts detected"
fi

# ============================================================================
# PHASE 2: Identify new files from merge
# ============================================================================
section "PHASE 2: Identify New Files"

# Get list of files added by the merge
# Compare current HEAD with merge base
MERGE_BASE=$(git merge-base HEAD HEAD~1 2>/dev/null || echo "HEAD~1")
NEW_FILES=$(git diff --name-only --diff-filter=A "$MERGE_BASE" HEAD 2>/dev/null || true)
NEW_COUNT=$(echo "$NEW_FILES" | grep -c . || echo 0)

info "Files added by merge: $NEW_COUNT"

if [[ $NEW_COUNT -gt 0 && $NEW_COUNT -lt 50 ]]; then
    echo ""
    echo "New files:"
    echo "$NEW_FILES" | head -20
fi

# ============================================================================
# PHASE 3: Quick prune of known removable directories
# ============================================================================
section "PHASE 3: Quick Prune Known Removable"

info "Removing files in known-removable directories..."
QUICK_REMOVED=0

# Known safe directories to remove
KNOWN_REMOVE=(
    "arch/alpha" "arch/arc" "arch/arm" "arch/arm64"
    "arch/csky" "arch/hexagon" "arch/loongarch" "arch/m68k"
    "arch/microblaze" "arch/mips" "arch/nios2" "arch/openrisc"
    "arch/parisc" "arch/powerpc" "arch/riscv" "arch/s390"
    "arch/sh" "arch/sparc" "arch/um" "arch/xtensa"
    "drivers/gpu/drm/amd" "drivers/gpu/drm/radeon" "drivers/gpu/drm/nouveau"
    "drivers/gpu/drm/msm" "drivers/gpu/drm/rockchip"
    "drivers/net/wireless/broadcom" "drivers/net/wireless/intel"
    "drivers/net/wireless/realtek" "drivers/net/wireless/mediatek"
    "drivers/media" "drivers/infiniband" "drivers/staging"
)

for dir in "${KNOWN_REMOVE[@]}"; do
    if [[ -d "$dir" ]]; then
        if [[ "$AUTO_MODE" == "1" ]]; then
            rm -rf "$dir"
            QUICK_REMOVED=$((QUICK_REMOVED + 1))
        else
            info "Would remove: $dir"
        fi
    fi
done

if [[ "$AUTO_MODE" == "1" ]]; then
    info "Quick-removed $QUICK_REMOVED directories"
else
    info "Run with --auto to remove these directories"
fi

# ============================================================================
# PHASE 4: Full manifest regeneration (optional)
# ============================================================================
section "PHASE 4: Regenerate Manifest"

if [[ "$AUTO_MODE" == "1" ]]; then
    info "Regenerating full manifest..."
    "$SCRIPT_DIR/generate_manifest.sh" --skip-build || warn "Manifest generation had errors"
else
    info "Skipping full manifest regeneration in interactive mode"
    info "Run: ./scripts/bespoke/generate_manifest.sh"
fi

# ============================================================================
# PHASE 5: Apply pruning
# ============================================================================
section "PHASE 5: Apply Pruning"

if [[ "$AUTO_MODE" == "1" ]]; then
    info "Applying pruning..."
    DRY_RUN=0 SKIP_VERIFY=1 "$SCRIPT_DIR/prune_tree.sh" || warn "Pruning had errors"
else
    info "Run these commands to complete pruning:"
    echo ""
    echo "  # Preview what would be removed:"
    echo "  DRY_RUN=1 ./scripts/bespoke/prune_tree.sh"
    echo ""
    echo "  # Apply pruning:"
    echo "  DRY_RUN=0 ./scripts/bespoke/prune_tree.sh"
fi

# ============================================================================
# PHASE 6: Verify build
# ============================================================================
section "PHASE 6: Verify Build"

if [[ "$AUTO_MODE" == "1" ]]; then
    info "Verifying kernel build..."
    if make -j"$(nproc)"; then
        info "Build verification PASSED"
    else
        error "Build verification FAILED"
    fi
else
    info "Run: make -j\$(nproc)"
fi

# ============================================================================
# Summary
# ============================================================================
section "POST-MERGE COMPLETE"

echo ""
if [[ "$AUTO_MODE" == "1" ]]; then
    echo "Merge has been processed and tree has been re-pruned."
    echo ""
    echo "Next steps:"
    echo "  1. Review changes: git status"
    echo "  2. Commit: git add -A && git commit -m 'Re-prune after upstream merge'"
    echo "  3. Boot test on hardware"
else
    echo "Review complete. To finish:"
    echo ""
    echo "  1. Resolve any remaining conflicts"
    echo "  2. Run: ./scripts/bespoke/generate_manifest.sh"
    echo "  3. Run: DRY_RUN=0 ./scripts/bespoke/prune_tree.sh"
    echo "  4. Verify: make -j\$(nproc)"
    echo "  5. Commit changes"
fi
