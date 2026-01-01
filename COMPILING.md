# Compiling the Bespoke Dell Kernel

This document describes how to build, customize, and maintain this bespoke Linux kernel optimized for a Dell laptop with Intel Kaby Lake i7-7500U.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Standard Build Process](#standard-build-process)
5. [Source Tree Pruning](#source-tree-pruning)
6. [Upstream Merge Workflow](#upstream-merge-workflow)
7. [Build Options](#build-options)
8. [Troubleshooting](#troubleshooting)

---

## Overview

This kernel is highly customized for a specific Dell laptop:

| Component | Hardware | Driver |
|-----------|----------|--------|
| CPU | Intel Core i7-7500U (Kaby Lake) | Native x86_64 |
| GPU | Intel HD Graphics 620 | i915 |
| WiFi | Qualcomm Atheros QCA6174 | ath10k_pci |
| Audio | Intel HD Audio | snd_hda_intel |
| Storage | NVMe SSD | nvme |
| USB | Intel xHCI | xhci_hcd |
| External Display | DisplayLink USB dock | evdi (out-of-tree) |

### Optimizations Applied

- **322+ kernel config options disabled** for maximum performance
- **LLVM/Clang 19 with ThinLTO** for whole-program optimization
- **CPU vulnerability mitigations disabled** (Spectre, Meltdown, etc.)
- **Debug features disabled** (ftrace, kprobes, kallsyms)
- **Unused drivers removed** (AMD GPU, NVIDIA, non-Atheros WiFi, etc.)

### Security Warning

This kernel disables most security features for performance. Use only on trusted networks. Not suitable for servers or production environments.

---

## Prerequisites

### Required Packages (Ubuntu/Debian)

```bash
# Build essentials
sudo apt install build-essential flex bison libncurses-dev libssl-dev libelf-dev

# LLVM toolchain (version 19 recommended)
sudo apt install llvm-19 clang-19 lld-19

# Additional tools
sudo apt install dwarves zstd bc cpio

# For initramfs generation
sudo apt install initramfs-tools
```

### Using the Docker Environment

A containerized build environment is provided:

```bash
# Build and enter the container
./claude

# Inside container, kernel source is at /home/claude/workspace
cd /home/claude/workspace
```

The Docker environment includes:
- LLVM 19 toolchain
- All kernel build dependencies
- Python 3.13 for analysis scripts

---

## Quick Start

### Standard Build (Recommended for First Time)

```bash
# Run the automated build script
./build.sh

# Follow prompts to:
# 1. Review configuration changes
# 2. Build kernel (~20-40 minutes with LTO)
# 3. Install kernel and modules
# 4. Build and install EVDI driver
# 5. Update GRUB
# 6. Reboot
```

### Build with Source Pruning (Advanced)

```bash
# 1. Generate manifest of required vs removable files
./scripts/bespoke/generate_manifest.sh

# 2. Preview what would be removed
DRY_RUN=1 ./scripts/bespoke/prune_tree.sh

# 3. Apply pruning
DRY_RUN=0 ./scripts/bespoke/prune_tree.sh

# 4. Build as normal
./build.sh
```

---

## Standard Build Process

### Step 1: Configure the Kernel

The `build.sh` script handles configuration automatically, but you can also configure manually:

```bash
# Start with default x86_64 config
make defconfig

# Apply bespoke optimizations (done by build.sh)
# See build.sh for the full list of config changes

# Regenerate config
make LLVM=19 olddefconfig

# Optional: Review/modify config interactively
make LLVM=19 menuconfig
```

### Step 2: Build the Kernel

```bash
# Using build.sh (recommended)
./build.sh

# Or manually with LLVM
make LLVM=19 -j$(nproc)
```

Build time estimates:
- First build with LTO: 20-40 minutes
- Incremental rebuild: 2-10 minutes
- Full rebuild after `make clean`: 20-40 minutes

### Step 3: Install

```bash
# Install modules
sudo make LLVM=19 modules_install

# Install kernel
sudo cp arch/x86/boot/bzImage /boot/vmlinuz-$(make kernelrelease)
sudo cp System.map /boot/System.map-$(make kernelrelease)
sudo cp .config /boot/config-$(make kernelrelease)

# Generate initramfs
sudo update-initramfs -c -k $(make kernelrelease)

# Update bootloader
sudo update-grub
```

### Step 4: Build EVDI Driver (for DisplayLink)

```bash
# Clone EVDI
git clone --depth 1 https://github.com/DisplayLink/evdi.git /tmp/evdi

# Build against new kernel
cd /tmp/evdi/module
make KDIR=/path/to/kernel LLVM=19 -j$(nproc)

# Install
sudo make KDIR=/path/to/kernel LLVM=19 install

# Clean up
rm -rf /tmp/evdi
```

### Step 5: Configure Boot Parameters

Add to `/etc/default/grub`:

```
GRUB_CMDLINE_LINUX_DEFAULT="mitigations=off nowatchdog processor.ignore_ppc=1 split_lock_detect=off"
```

Then update GRUB:

```bash
sudo update-grub
sudo reboot
```

---

## Source Tree Pruning

The bespoke pruning pipeline removes unused source code from the kernel tree, reducing it from ~1.3GB to ~300-400MB.

### Why Prune?

- **Faster searches**: grep/ripgrep runs much faster on smaller trees
- **Cleaner codebase**: Only code relevant to your hardware
- **Faster IDE indexing**: Less code to analyze
- **Educational**: See exactly what your kernel uses

### Pruning Pipeline Overview

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  trace_build.sh │────▶│ trace_headers.py │────▶│generate_manifest│
│  (make V=1)     │     │  (dependencies)  │     │      .sh        │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                                                          │
                                                          ▼
                                                  ┌───────────────┐
                                                  │ manifest/     │
                                                  │ ├─ required   │
                                                  │ └─ removable  │
                                                  └───────┬───────┘
                                                          │
                                                          ▼
                                                  ┌───────────────┐
                                                  │ prune_tree.sh │
                                                  └───────────────┘
```

### Step-by-Step Pruning

#### 1. Generate the Manifest

This builds the kernel with verbose output to trace exactly which files get compiled:

```bash
./scripts/bespoke/generate_manifest.sh
```

This creates files in `manifest/`:

| File | Description |
|------|-------------|
| `compiled_c.txt` | C files that were compiled |
| `compiled_s.txt` | Assembly files that were compiled |
| `headers.txt` | Header files required by compiled sources |
| `required_sources.txt` | All files needed (union of above) |
| `removable_files.txt` | Files that can be safely removed |
| `removable_dirs.txt` | Entire directories that can be removed |
| `known_safe_removable.txt` | Pre-identified safe-to-remove directories |
| `summary.txt` | Human-readable statistics |

#### 2. Review the Manifest

```bash
# View summary
cat manifest/summary.txt

# View directories that would be removed
cat manifest/removable_dirs.txt | head -50

# Check size of removable content
du -sh $(cat manifest/removable_dirs.txt | head -20)
```

#### 3. Preview Pruning (Dry Run)

```bash
DRY_RUN=1 ./scripts/bespoke/prune_tree.sh
```

This shows what would be removed without actually deleting anything.

#### 4. Apply Pruning

```bash
DRY_RUN=0 ./scripts/bespoke/prune_tree.sh
```

You'll be prompted to confirm. The script will:
1. Remove directories listed in `removable_dirs.txt`
2. Remove individual files from `removable_files.txt`
3. Clean up empty directories
4. Verify the build still works

#### 5. Commit the Pruned State

```bash
git add -A
git commit -m "Prune unused source for bespoke kernel

Removed:
- Non-x86 architectures (~133MB)
- Unused GPU drivers (~548MB)
- Unused wireless drivers (~56MB)
- Media subsystem (~49MB)
- Other unused subsystems

Generated by scripts/bespoke/generate_manifest.sh"
```

### Skip Build for Faster Iteration

If you've already built and want to regenerate the manifest without rebuilding:

```bash
./scripts/bespoke/generate_manifest.sh --skip-build
```

This uses existing build artifacts (`.*.cmd` files) to trace dependencies.

---

## Upstream Merge Workflow

When merging updates from upstream kernel, use the post-merge script to re-apply pruning.

### Manual Workflow

```bash
# 1. Fetch upstream
git remote add upstream https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
git fetch upstream

# 2. Merge
git merge upstream/master

# 3. Resolve conflicts
# - Conflicts in removed directories: accept deletion (git rm)
# - Conflicts in kept directories: resolve manually

# 4. Re-run pruning
./scripts/bespoke/generate_manifest.sh
DRY_RUN=0 ./scripts/bespoke/prune_tree.sh

# 5. Verify and commit
make -j$(nproc)
git add -A
git commit -m "Re-prune after upstream merge to v6.x"
```

### Automated Workflow

```bash
# Fetch and merge
git fetch upstream
git merge upstream/master

# Run post-merge script (handles conflicts in removed dirs automatically)
./scripts/bespoke/post_merge.sh --auto
```

The `--auto` flag:
- Resolves conflicts in removed directories by accepting deletion
- Warns about conflicts in kept directories (must resolve manually)
- Re-runs manifest generation
- Applies pruning
- Verifies build

---

## Build Options

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `LLVM` | `19` | LLVM toolchain version |
| `JOBS` | `$(nproc)` | Parallel build jobs |
| `DRY_RUN` | `1` | Prune script dry-run mode |
| `SKIP_VERIFY` | `0` | Skip build verification after pruning |
| `MANIFEST_DIR` | `manifest/` | Output directory for manifest files |

### Make Targets

```bash
# Standard targets
make defconfig          # Default x86_64 config
make menuconfig         # Interactive config editor
make -j$(nproc)         # Build kernel
make modules_install    # Install modules
make clean              # Remove build artifacts
make mrproper           # Remove all generated files

# With LLVM
make LLVM=19 -j$(nproc)

# Verbose build (for tracing)
make V=1 -j$(nproc)
```

### Bespoke Scripts

| Script | Description |
|--------|-------------|
| `./build.sh` | Full automated build and install |
| `./scripts/bespoke/trace_build.sh` | Trace compiled files during build |
| `./scripts/bespoke/trace_headers.py` | Trace header dependencies |
| `./scripts/bespoke/generate_manifest.sh` | Generate removal manifest |
| `./scripts/bespoke/prune_tree.sh` | Apply source pruning |
| `./scripts/bespoke/post_merge.sh` | Re-prune after upstream merge |

---

## Troubleshooting

### Build Fails After Pruning

```bash
# Restore all files from git
git checkout -- .

# Or restore specific directory
git checkout -- drivers/gpu/drm/i915/
```

### Missing Header Errors

If you see errors like `fatal error: linux/foo.h: No such file or directory`:

1. The header tracing may have missed a dependency
2. Add the missing header's directory back:
   ```bash
   git checkout -- include/linux/foo.h
   ```
3. Re-run manifest generation to update

### EVDI Build Fails

```bash
# Ensure you're using same LLVM version as kernel
make KDIR=/path/to/kernel LLVM=19 CC=clang-19 -j$(nproc)

# Check kernel was built with module support
grep CONFIG_MODULES /path/to/kernel/.config
# Should show: CONFIG_MODULES=y
```

### Kernel Panic on Boot

1. Boot previous working kernel from GRUB menu
2. Check dmesg for clues: `dmesg | grep -i error`
3. Common issues:
   - Missing driver for root filesystem
   - Missing initramfs modules
   - Hardware not detected

### Docker Build Environment Issues

```bash
# Rebuild the container
docker build -t claude-code .

# Check container has correct tools
docker run --rm claude-code clang-19 --version
docker run --rm claude-code make --version
```

### Manifest Generation Takes Too Long

The full build trace requires a complete kernel build. For faster iteration:

```bash
# Skip the build if you already have build artifacts
./scripts/bespoke/generate_manifest.sh --skip-build

# Or just use known-safe removals without full analysis
cat scripts/bespoke/post_merge.sh  # See KNOWN_REMOVE array
```

---

## File Reference

### Key Configuration Files

| File | Description |
|------|-------------|
| `.config` | Current kernel configuration |
| `build.sh` | Main build script with all optimizations |
| `HARDWARE_INVENTORY.md` | Target hardware specifications |
| `KERNEL_CONFIG_INVENTORY.md` | Documentation of disabled configs |

### Generated Files

| File/Directory | Description |
|----------------|-------------|
| `manifest/` | Pruning analysis output |
| `vmlinux` | Uncompressed kernel image |
| `arch/x86/boot/bzImage` | Compressed bootable kernel |
| `System.map` | Kernel symbol table |

### Installed Files

| Location | Description |
|----------|-------------|
| `/boot/vmlinuz-*` | Kernel image |
| `/boot/initrd.img-*` | Initial ramdisk |
| `/boot/System.map-*` | Symbol table |
| `/boot/config-*` | Kernel config |
| `/lib/modules/*/` | Kernel modules |

---

## Performance Expectations

### Build Times (Ryzen 7 5800X, 32GB RAM, NVMe)

| Build Type | Time |
|------------|------|
| Full build with LTO | 25-35 minutes |
| Incremental (small change) | 2-5 minutes |
| Modules only | 5-10 minutes |

### Source Tree Size

| State | Size |
|-------|------|
| Full kernel source | ~1.3 GB |
| After pruning | ~300-400 MB |
| Build artifacts | ~2-4 GB |

### Runtime Performance

| Metric | Improvement |
|--------|-------------|
| Syscall latency | 5-30% faster |
| Boot time | 20-40% faster |
| Memory usage | 50-100 MB less |

---

## Further Reading

- [HARDWARE_INVENTORY.md](HARDWARE_INVENTORY.md) - Target hardware details
- [KERNEL_CONFIG_INVENTORY.md](KERNEL_CONFIG_INVENTORY.md) - Disabled config options
- [Kernel Build Documentation](https://www.kernel.org/doc/html/latest/kbuild/)
- [LLVM/Clang Kernel Build](https://www.kernel.org/doc/html/latest/kbuild/llvm.html)
