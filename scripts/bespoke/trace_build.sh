#!/bin/bash
# ============================================================================
# TRACE BUILD - Capture all source files compiled during kernel build
# ============================================================================
# This script performs a full kernel build with verbose output to determine
# exactly which source files get compiled for the current configuration.
#
# Output:
#   - build_trace.log: Full verbose build output
#   - compiled_c.txt: List of all .c files compiled
#   - compiled_s.txt: List of all .S assembly files compiled
#
# Usage:
#   ./scripts/bespoke/trace_build.sh [output_dir]
#
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="${1:-$KERNEL_DIR/manifest}"

BUILD_LOG="$OUTPUT_DIR/build_trace.log"
COMPILED_C="$OUTPUT_DIR/compiled_c.txt"
COMPILED_S="$OUTPUT_DIR/compiled_s.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# Ensure we're in kernel directory
cd "$KERNEL_DIR"

if [[ ! -f "Makefile" ]] || ! grep -q "VERSION = 6" Makefile; then
    error "Must run from kernel source root (expected Linux 6.x)"
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Check if .config exists
if [[ ! -f ".config" ]]; then
    warn "No .config found. Running config.sh to generate configuration..."
    if [[ -x "$SCRIPT_DIR/config.sh" ]]; then
        info "Generating kernel configuration via config.sh..."
        "$SCRIPT_DIR/config.sh"
    else
        error "No .config and no config.sh found. Please configure kernel first."
    fi
fi

info "Starting build trace..."
info "Output directory: $OUTPUT_DIR"

# Clean build artifacts but keep config
info "Cleaning build artifacts (keeping .config)..."
make clean

# Determine compiler to use
if command -v clang &>/dev/null && [[ -n "${LLVM:-}" ]]; then
    info "Using LLVM/Clang toolchain"
    MAKE_ARGS="LLVM=1"
else
    info "Using GCC toolchain"
    MAKE_ARGS=""
fi

# Build with verbose output
info "Building kernel with verbose output (this may take a while)..."
info "Build log: $BUILD_LOG"

# Use V=1 for verbose output showing all compilation commands
# Redirect both stdout and stderr to log file while also showing progress
if ! make V=1 $MAKE_ARGS -j"$(nproc)" 2>&1 | tee "$BUILD_LOG"; then
    warn "Build completed with some errors (this may be OK for tracing purposes)"
fi

info "Build complete. Extracting compiled file list..."

# Extract compiled C files
# Pattern matches lines like:
#   CC      kernel/sched/core.o
#   CC [M]  drivers/gpu/drm/i915/display/intel_display.o
info "Extracting compiled .c files..."
grep -oP '^\s*CC\s+(\[M\]\s+)?\K\S+\.o' "$BUILD_LOG" 2>/dev/null | \
    sed 's|\.o$|.c|' | \
    sort -u > "$COMPILED_C" || true

# Also try alternate pattern for build systems that use different formatting
grep -oP 'CC\s+\S+\.o' "$BUILD_LOG" 2>/dev/null | \
    awk '{print $2}' | \
    sed 's|\.o$|.c|' | \
    sort -u >> "$COMPILED_C" || true

# Deduplicate
sort -u "$COMPILED_C" -o "$COMPILED_C"

# Extract compiled assembly files
info "Extracting compiled .S files..."
grep -oP '^\s*AS\s+(\[M\]\s+)?\K\S+\.o' "$BUILD_LOG" 2>/dev/null | \
    sed 's|\.o$|.S|' | \
    sort -u > "$COMPILED_S" || true

# Also check for .s files (preprocessed assembly)
grep -oP 'AS\s+\S+\.o' "$BUILD_LOG" 2>/dev/null | \
    awk '{print $2}' | \
    sed 's|\.o$|.S|' | \
    sort -u >> "$COMPILED_S" || true

# Deduplicate
sort -u "$COMPILED_S" -o "$COMPILED_S"

# Extract hostcc compiled files (build tools)
info "Extracting host tools compiled..."
grep -oP '^\s*HOSTCC\s+\K\S+' "$BUILD_LOG" 2>/dev/null | \
    sort -u > "$OUTPUT_DIR/compiled_host.txt" || true

# Summary
C_COUNT=$(wc -l < "$COMPILED_C" 2>/dev/null || echo "0")
S_COUNT=$(wc -l < "$COMPILED_S" 2>/dev/null || echo "0")
HOST_COUNT=$(wc -l < "$OUTPUT_DIR/compiled_host.txt" 2>/dev/null || echo "0")

echo ""
info "============================================"
info "BUILD TRACE COMPLETE"
info "============================================"
info "Compiled C files:     $C_COUNT"
info "Compiled ASM files:   $S_COUNT"
info "Host tools compiled:  $HOST_COUNT"
info ""
info "Output files:"
info "  - $BUILD_LOG"
info "  - $COMPILED_C"
info "  - $COMPILED_S"
info "  - $OUTPUT_DIR/compiled_host.txt"
info "============================================"
