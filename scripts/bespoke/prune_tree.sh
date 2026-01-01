#!/bin/bash
# ============================================================================
# PRUNE TREE - Remove unused source files from kernel tree
# ============================================================================
#
# This script removes files and directories identified as unused by the
# manifest generation process. It supports dry-run mode by default.
#
# Usage:
#   DRY_RUN=1 ./scripts/bespoke/prune_tree.sh  # Preview (default)
#   DRY_RUN=0 ./scripts/bespoke/prune_tree.sh  # Actually remove files
#
# Options (via environment):
#   DRY_RUN=1        Preview what would be removed (default)
#   DRY_RUN=0        Actually remove files
#   MANIFEST_DIR=    Directory containing manifest files (default: manifest/)
#   SKIP_VERIFY=1    Skip build verification after pruning
#
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
MANIFEST_DIR="${MANIFEST_DIR:-$KERNEL_DIR/manifest}"
DRY_RUN="${DRY_RUN:-1}"
SKIP_VERIFY="${SKIP_VERIFY:-0}"

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
dry() { echo -e "${YELLOW}[DRY]${NC} $*"; }

cd "$KERNEL_DIR"

# Verify we're in kernel source
if [[ ! -f "Makefile" ]] || ! grep -q "VERSION = 6" Makefile; then
    error "Must run from kernel source root"
fi

# Check for manifest
if [[ ! -f "$MANIFEST_DIR/removable_dirs.txt" ]]; then
    error "Manifest not found. Run generate_manifest.sh first."
fi

section "BESPOKE KERNEL PRUNING"
if [[ "$DRY_RUN" == "1" ]]; then
    echo -e "${BOLD}${YELLOW}MODE: DRY RUN (no files will be removed)${NC}"
    echo "Set DRY_RUN=0 to actually remove files"
else
    echo -e "${BOLD}${RED}MODE: LIVE (files will be permanently removed!)${NC}"
    echo ""
    read -p "Are you sure you want to proceed? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        info "Aborted."
        exit 0
    fi
fi
echo ""

# Track statistics
DIRS_REMOVED=0
FILES_REMOVED=0
BYTES_SAVED=0

# ============================================================================
# PHASE 1: Remove entire directories
# ============================================================================
section "PHASE 1: Remove Directories"

info "Processing removable directories..."

while IFS= read -r dir; do
    [[ -z "$dir" ]] && continue
    [[ ! -d "$dir" ]] && continue

    # Calculate size before removal
    dir_size=$(du -sb "$dir" 2>/dev/null | cut -f1 || echo 0)

    if [[ "$DRY_RUN" == "1" ]]; then
        dry "rm -rf $dir ($(numfmt --to=iec $dir_size 2>/dev/null || echo "${dir_size}B"))"
    else
        rm -rf "$dir"
        info "Removed: $dir"
    fi

    DIRS_REMOVED=$((DIRS_REMOVED + 1))
    BYTES_SAVED=$((BYTES_SAVED + dir_size))
done < "$MANIFEST_DIR/removable_dirs.txt"

# Also process known safe directories if they exist
if [[ -f "$MANIFEST_DIR/known_safe_removable.txt" ]]; then
    info "Processing known-safe directories..."
    while IFS= read -r dir; do
        [[ -z "$dir" ]] && continue
        [[ ! -d "$dir" ]] && continue

        # Skip if already removed (might be subdir of already removed dir)
        [[ ! -d "$dir" ]] && continue

        dir_size=$(du -sb "$dir" 2>/dev/null | cut -f1 || echo 0)

        if [[ "$DRY_RUN" == "1" ]]; then
            dry "rm -rf $dir ($(numfmt --to=iec $dir_size 2>/dev/null || echo "${dir_size}B"))"
        else
            rm -rf "$dir"
            info "Removed: $dir"
        fi

        DIRS_REMOVED=$((DIRS_REMOVED + 1))
        BYTES_SAVED=$((BYTES_SAVED + dir_size))
    done < "$MANIFEST_DIR/known_safe_removable.txt"
fi

# ============================================================================
# PHASE 2: Remove individual files
# ============================================================================
section "PHASE 2: Remove Individual Files"

info "Processing removable files..."
file_count=0
skipped=0

while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    [[ ! -f "$file" ]] && continue

    # Skip files in already-removed directories
    dir=$(dirname "$file")
    if ! [[ -d "$dir" ]]; then
        skipped=$((skipped + 1))
        continue
    fi

    file_size=$(stat --format=%s "$file" 2>/dev/null || echo 0)

    if [[ "$DRY_RUN" == "1" ]]; then
        # Only show first 50 files in dry run to avoid spam
        if [[ $file_count -lt 50 ]]; then
            dry "rm $file"
        elif [[ $file_count -eq 50 ]]; then
            dry "... and more files (see removable_files.txt for full list)"
        fi
    else
        rm -f "$file"
    fi

    FILES_REMOVED=$((FILES_REMOVED + 1))
    BYTES_SAVED=$((BYTES_SAVED + file_size))
    file_count=$((file_count + 1))
done < "$MANIFEST_DIR/removable_files.txt"

if [[ $skipped -gt 0 ]]; then
    info "Skipped $skipped files (already removed with parent directories)"
fi

# ============================================================================
# PHASE 3: Fix Kconfig references to removed directories
# ============================================================================
section "PHASE 3: Fix Kconfig References"

info "Scanning Kconfig files for broken references..."
KCONFIG_FIXES=0

fix_kconfig_file() {
    local kconfig_file="$1"
    local temp_file=$(mktemp)
    local modified=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^([[:space:]]*)(source[[:space:]]+\"([^\"]+)\") ]]; then
            local indent="${BASH_REMATCH[1]}"
            local source_stmt="${BASH_REMATCH[2]}"
            local path="${BASH_REMATCH[3]}"

            # Skip template paths with variables like $(SRCARCH)
            if [[ "$path" == *'$('* ]]; then
                echo "$line" >> "$temp_file"
                continue
            fi

            if [[ ! -f "$path" ]]; then
                if [[ "$DRY_RUN" == "1" ]]; then
                    dry "Comment out: $path (in $kconfig_file)"
                else
                    echo "${indent}# ${source_stmt}  # pruned" >> "$temp_file"
                fi
                modified=1
                KCONFIG_FIXES=$((KCONFIG_FIXES + 1))
                continue
            fi
        fi
        echo "$line" >> "$temp_file"
    done < "$kconfig_file"

    if [[ $modified -eq 1 && "$DRY_RUN" == "0" ]]; then
        mv "$temp_file" "$kconfig_file"
        info "Fixed: $kconfig_file"
    else
        rm -f "$temp_file"
    fi
}

while IFS= read -r kconfig; do
    fix_kconfig_file "$kconfig"
done < <(find . -name "Kconfig" -o -name "Kconfig.*" 2>/dev/null | grep -v ".git")

if [[ $KCONFIG_FIXES -gt 0 ]]; then
    info "Fixed $KCONFIG_FIXES Kconfig source references"
else
    info "No broken Kconfig references found"
fi

# ============================================================================
# PHASE 4: Clean up empty directories
# ============================================================================
section "PHASE 4: Clean Empty Directories"

if [[ "$DRY_RUN" == "0" ]]; then
    info "Removing empty directories..."
    find . -type d -empty -delete 2>/dev/null || true
    info "Empty directories cleaned"
else
    empty_dirs=$(find . -type d -empty 2>/dev/null | wc -l || echo 0)
    dry "Would remove $empty_dirs empty directories"
fi

# ============================================================================
# PHASE 5: Verify build (optional)
# ============================================================================
if [[ "$DRY_RUN" == "0" && "$SKIP_VERIFY" == "0" ]]; then
    section "PHASE 5: Verify Build"

    info "Verifying kernel still builds..."
    if make -j"$(nproc)" 2>&1 | tail -20; then
        info "Build verification PASSED"
    else
        warn "Build verification FAILED - you may need to restore some files"
        warn "Use git to restore: git checkout -- <path>"
    fi
fi

# ============================================================================
# Summary
# ============================================================================
section "PRUNING SUMMARY"

# Convert bytes to human readable
if command -v numfmt &>/dev/null; then
    HUMAN_SAVED=$(numfmt --to=iec $BYTES_SAVED 2>/dev/null || echo "${BYTES_SAVED}B")
else
    HUMAN_SAVED="$((BYTES_SAVED / 1024 / 1024))MB"
fi

if [[ "$DRY_RUN" == "1" ]]; then
    echo -e "${BOLD}DRY RUN COMPLETE${NC}"
    echo ""
    echo "Would remove:"
    echo "  - $DIRS_REMOVED directories"
    echo "  - $FILES_REMOVED individual files"
    echo "  - Estimated savings: $HUMAN_SAVED"
    echo ""
    echo "To actually remove files, run:"
    echo "  DRY_RUN=0 $0"
else
    echo -e "${BOLD}${GREEN}PRUNING COMPLETE${NC}"
    echo ""
    echo "Removed:"
    echo "  - $DIRS_REMOVED directories"
    echo "  - $FILES_REMOVED individual files"
    echo "  - Space saved: $HUMAN_SAVED"
    echo ""

    # Show new tree size
    NEW_SIZE=$(du -sh "$KERNEL_DIR" 2>/dev/null | cut -f1)
    echo "New source tree size: $NEW_SIZE"
    echo ""
    echo "Next steps:"
    echo "  1. Verify build: make -j\$(nproc)"
    echo "  2. Install: sudo make modules_install && sudo make install"
    echo "  3. Boot test on actual hardware"
    echo ""
    echo "To undo, use git:"
    echo "  git checkout -- ."
fi
