#!/bin/bash
# ============================================================================
# GENERATE MANIFEST - Create list of files to keep/remove for bespoke kernel
# ============================================================================
#
# This is the master script that:
# 1. Runs trace_build.sh to identify compiled source files
# 2. Runs trace_headers.py to identify required headers
# 3. Identifies build system files (Kconfig, Makefile, scripts/)
# 4. Compares against full source tree
# 5. Outputs manifest of required vs removable files
#
# Usage:
#   ./scripts/bespoke/generate_manifest.sh [--skip-build] [--output-dir DIR]
#
# Options:
#   --skip-build    Skip the kernel build (use existing build artifacts)
#   --output-dir    Output directory for manifest files (default: manifest/)
#
# Output files in manifest/:
#   - compiled_c.txt         Compiled C source files
#   - compiled_s.txt         Compiled assembly files
#   - headers.txt            Required header files
#   - required_sources.txt   All required source files
#   - removable_files.txt    Files that can be safely removed
#   - removable_dirs.txt     Directories that can be entirely removed
#   - summary.txt            Human-readable summary
#
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
MANIFEST_DIR="$KERNEL_DIR/manifest"
SKIP_BUILD=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
section() { echo -e "\n${CYAN}=== $* ===${NC}"; }

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-build)
            SKIP_BUILD=1
            shift
            ;;
        --output-dir)
            MANIFEST_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--skip-build] [--output-dir DIR]"
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

mkdir -p "$MANIFEST_DIR"

section "BESPOKE KERNEL MANIFEST GENERATION"
info "Kernel directory: $KERNEL_DIR"
info "Output directory: $MANIFEST_DIR"
echo ""

# ============================================================================
# PHASE 1: Trace compiled sources
# ============================================================================
section "PHASE 1: Trace Compiled Sources"

if [[ $SKIP_BUILD -eq 0 ]]; then
    info "Running build trace (this will take a while)..."
    if ! "$SCRIPT_DIR/trace_build.sh" "$MANIFEST_DIR"; then
        warn "Build trace had errors, continuing anyway..."
    fi
else
    info "Skipping build trace (using existing artifacts)"
    if [[ ! -f "$MANIFEST_DIR/compiled_c.txt" ]]; then
        error "No compiled_c.txt found. Run without --skip-build first."
    fi
fi

# ============================================================================
# PHASE 2: Trace header dependencies
# ============================================================================
section "PHASE 2: Trace Header Dependencies"

if [[ -f "$MANIFEST_DIR/compiled_c.txt" ]]; then
    info "Tracing headers from compiled C files..."
    python3 "$SCRIPT_DIR/trace_headers.py" \
        "$MANIFEST_DIR/compiled_c.txt" \
        "$KERNEL_DIR" \
        -o "$MANIFEST_DIR/headers_c.txt" \
        -v || warn "Header tracing had some errors"
fi

if [[ -f "$MANIFEST_DIR/compiled_s.txt" ]]; then
    info "Tracing headers from compiled ASM files..."
    python3 "$SCRIPT_DIR/trace_headers.py" \
        "$MANIFEST_DIR/compiled_s.txt" \
        "$KERNEL_DIR" \
        -o "$MANIFEST_DIR/headers_s.txt" \
        -v || warn "Header tracing had some errors"
fi

# Combine headers
cat "$MANIFEST_DIR/headers_c.txt" "$MANIFEST_DIR/headers_s.txt" 2>/dev/null | \
    sort -u > "$MANIFEST_DIR/headers.txt" || true

# ============================================================================
# PHASE 3: Identify build infrastructure files
# ============================================================================
section "PHASE 3: Identify Build Infrastructure"

info "Finding Kconfig files..."
find . -name 'Kconfig*' -type f 2>/dev/null | \
    sed 's|^\./||' | sort > "$MANIFEST_DIR/kconfig_files.txt"

info "Finding Makefile/Kbuild files..."
find . \( -name 'Makefile*' -o -name 'Kbuild*' \) -type f 2>/dev/null | \
    sed 's|^\./||' | sort > "$MANIFEST_DIR/makefile_files.txt"

info "Finding scripts/ files..."
find scripts/ -type f 2>/dev/null | \
    sed 's|^\./||' | sort > "$MANIFEST_DIR/scripts_files.txt" || true

info "Finding tools/ files..."
find tools/ -type f 2>/dev/null | \
    sed 's|^\./||' | sort > "$MANIFEST_DIR/tools_files.txt" || true

info "Finding documentation files..."
find Documentation/ -type f 2>/dev/null | \
    sed 's|^\./||' | sort > "$MANIFEST_DIR/docs_files.txt" || true

# ============================================================================
# PHASE 4: Find all source files in tree
# ============================================================================
section "PHASE 4: Catalog All Source Files"

info "Finding all C source files..."
find . -name '*.c' -type f 2>/dev/null | \
    sed 's|^\./||' | sort > "$MANIFEST_DIR/all_c.txt"

info "Finding all assembly files..."
find . -name '*.S' -type f 2>/dev/null | \
    sed 's|^\./||' | sort > "$MANIFEST_DIR/all_s.txt"

info "Finding all header files..."
find . -name '*.h' -type f 2>/dev/null | \
    sed 's|^\./||' | sort > "$MANIFEST_DIR/all_h.txt"

# Combine all source files
cat "$MANIFEST_DIR/all_c.txt" \
    "$MANIFEST_DIR/all_s.txt" \
    "$MANIFEST_DIR/all_h.txt" | sort -u > "$MANIFEST_DIR/all_sources.txt"

# ============================================================================
# PHASE 5: Calculate required vs removable
# ============================================================================
section "PHASE 5: Calculate Required vs Removable Files"

info "Combining required files..."
cat "$MANIFEST_DIR/compiled_c.txt" \
    "$MANIFEST_DIR/compiled_s.txt" \
    "$MANIFEST_DIR/headers.txt" \
    2>/dev/null | sort -u > "$MANIFEST_DIR/required_sources.txt" || true

info "Calculating removable files..."
comm -23 "$MANIFEST_DIR/all_sources.txt" \
         "$MANIFEST_DIR/required_sources.txt" > "$MANIFEST_DIR/removable_files.txt"

# ============================================================================
# PHASE 6: Identify removable directories
# ============================================================================
section "PHASE 6: Identify Removable Directories"

info "Analyzing directory structure..."
python3 - "$MANIFEST_DIR" << 'PYTHON_SCRIPT'
import sys
from pathlib import Path
from collections import defaultdict

manifest_dir = Path(sys.argv[1])

# Load file lists
all_files = set((manifest_dir / 'all_sources.txt').read_text().splitlines())
required = set((manifest_dir / 'required_sources.txt').read_text().splitlines())

# Group by directory
dir_files = defaultdict(set)
for f in all_files:
    dir_files[str(Path(f).parent)].add(f)

# Find directories where NO files are required
removable_dirs = []
for d, files in dir_files.items():
    if not (files & required):
        removable_dirs.append(d)

# Sort by path length (shortest first) to find top-level removable dirs
removable_dirs.sort(key=len)

# Filter to only top-level removable directories
# (don't list subdirs if parent is already removable)
final_dirs = []
for d in removable_dirs:
    # Check if any parent is already in the list
    is_subdir = False
    for parent in final_dirs:
        if d.startswith(parent + '/'):
            is_subdir = True
            break
    if not is_subdir:
        final_dirs.append(d)

# Write output
with open(manifest_dir / 'removable_dirs.txt', 'w') as f:
    for d in sorted(final_dirs):
        f.write(d + '\n')

# Also identify "known safe" removable directories (entire subsystems)
known_safe = [
    # Non-x86 architectures
    'arch/alpha', 'arch/arc', 'arch/arm', 'arch/arm64',
    'arch/csky', 'arch/hexagon', 'arch/loongarch', 'arch/m68k',
    'arch/microblaze', 'arch/mips', 'arch/nios2', 'arch/openrisc',
    'arch/parisc', 'arch/powerpc', 'arch/riscv', 'arch/s390',
    'arch/sh', 'arch/sparc', 'arch/um', 'arch/xtensa',
    # GPU drivers (keeping i915)
    'drivers/gpu/drm/amd', 'drivers/gpu/drm/radeon', 'drivers/gpu/drm/nouveau',
    'drivers/gpu/drm/msm', 'drivers/gpu/drm/rockchip', 'drivers/gpu/drm/mediatek',
    'drivers/gpu/drm/exynos', 'drivers/gpu/drm/tegra', 'drivers/gpu/drm/vc4',
    'drivers/gpu/drm/v3d', 'drivers/gpu/drm/etnaviv', 'drivers/gpu/drm/lima',
    'drivers/gpu/drm/panfrost', 'drivers/gpu/drm/virtio', 'drivers/gpu/drm/vmwgfx',
    # Wireless drivers (keeping ath/)
    'drivers/net/wireless/broadcom', 'drivers/net/wireless/intel',
    'drivers/net/wireless/realtek', 'drivers/net/wireless/mediatek',
    'drivers/net/wireless/marvell', 'drivers/net/wireless/ralink',
    # Other subsystems
    'drivers/media', 'drivers/infiniband', 'drivers/staging',
    'drivers/isdn', 'drivers/atm', 'drivers/firewire',
    'drivers/macintosh', 'drivers/ps3',
]

with open(manifest_dir / 'known_safe_removable.txt', 'w') as f:
    for d in sorted(known_safe):
        if Path(d).exists():
            f.write(d + '\n')

print(f"Identified {len(final_dirs)} removable directories")
print(f"Identified {sum(1 for d in known_safe if Path(d).exists())} known-safe directories")
PYTHON_SCRIPT

# ============================================================================
# PHASE 7: Generate summary
# ============================================================================
section "PHASE 7: Generate Summary"

# Calculate statistics
ALL_C=$(wc -l < "$MANIFEST_DIR/all_c.txt" 2>/dev/null || echo 0)
ALL_S=$(wc -l < "$MANIFEST_DIR/all_s.txt" 2>/dev/null || echo 0)
ALL_H=$(wc -l < "$MANIFEST_DIR/all_h.txt" 2>/dev/null || echo 0)
ALL_TOTAL=$(wc -l < "$MANIFEST_DIR/all_sources.txt" 2>/dev/null || echo 0)

COMPILED_C=$(wc -l < "$MANIFEST_DIR/compiled_c.txt" 2>/dev/null || echo 0)
COMPILED_S=$(wc -l < "$MANIFEST_DIR/compiled_s.txt" 2>/dev/null || echo 0)
HEADERS=$(wc -l < "$MANIFEST_DIR/headers.txt" 2>/dev/null || echo 0)
REQUIRED=$(wc -l < "$MANIFEST_DIR/required_sources.txt" 2>/dev/null || echo 0)

REMOVABLE_FILES=$(wc -l < "$MANIFEST_DIR/removable_files.txt" 2>/dev/null || echo 0)
REMOVABLE_DIRS=$(wc -l < "$MANIFEST_DIR/removable_dirs.txt" 2>/dev/null || echo 0)

# Calculate sizes
TOTAL_SIZE=$(du -sh "$KERNEL_DIR" 2>/dev/null | cut -f1)
REMOVABLE_SIZE=$(cat "$MANIFEST_DIR/removable_files.txt" | \
    xargs -I{} stat --format=%s "{}" 2>/dev/null | \
    awk '{s+=$1} END {printf "%.0f", s/1024/1024}' || echo "?")

# Generate summary file
cat > "$MANIFEST_DIR/summary.txt" << EOF
============================================================================
BESPOKE KERNEL MANIFEST SUMMARY
Generated: $(date)
============================================================================

SOURCE TREE STATISTICS
----------------------
Total C files:        $ALL_C
Total ASM files:      $ALL_S
Total Header files:   $ALL_H
Total source files:   $ALL_TOTAL
Current tree size:    $TOTAL_SIZE

COMPILED FILES (Required)
------------------------
Compiled C files:     $COMPILED_C
Compiled ASM files:   $COMPILED_S
Required headers:     $HEADERS
Total required:       $REQUIRED

REMOVABLE FILES
---------------
Removable files:      $REMOVABLE_FILES
Removable dirs:       $REMOVABLE_DIRS
Estimated savings:    ${REMOVABLE_SIZE}MB

PERCENTAGE ANALYSIS
-------------------
Required:  $(awk "BEGIN {printf \"%.1f\", ($REQUIRED/$ALL_TOTAL)*100}")%
Removable: $(awk "BEGIN {printf \"%.1f\", ($REMOVABLE_FILES/$ALL_TOTAL)*100}")%

FILES IN THIS MANIFEST
----------------------
$(ls -la "$MANIFEST_DIR"/*.txt 2>/dev/null || echo "(none)")

NEXT STEPS
----------
1. Review removable_dirs.txt for large directory removals
2. Review removable_files.txt for individual file removals
3. Run: DRY_RUN=1 ./scripts/bespoke/prune_tree.sh  (preview)
4. Run: DRY_RUN=0 ./scripts/bespoke/prune_tree.sh  (apply)
5. Verify build: make -j\$(nproc)
6. Boot test on actual hardware

============================================================================
EOF

# Display summary
cat "$MANIFEST_DIR/summary.txt"

info ""
info "Manifest generation complete!"
info "Output directory: $MANIFEST_DIR"
