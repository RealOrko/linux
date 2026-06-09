#!/bin/bash

set -e

# Remove all custom 6.18 kernels from /boot (keeps Ubuntu 6.14 kernels)
sudo rm -f /boot/*6.18.0*

# Remove all custom 6.18 modules
sudo rm -rf /lib/modules/6.18.0*

# Update GRUB
sudo update-grub

LLVM_VERSION="-19"
JOBS=$(nproc)

echo "=== Maximum Performance Kernel Build ==="
echo "Using LLVM 19 toolchain with $JOBS parallel jobs"
echo ""

#######################################
# ENSURE CONFIG AND GENERATED HEADERS EXIST
#######################################
# Create .config from running kernel if it doesn't exist
if [ ! -f .config ]; then
    echo "[*] No .config found, copying from running kernel..."
    cp /boot/config-$(uname -r) .config
    echo "[+] Created .config from /boot/config-$(uname -r)"
fi

# Ensure generated/autoconf.h exists (required for builds after make mrproper)
if [ ! -f include/generated/autoconf.h ]; then
    echo "[*] Generated headers missing, running olddefconfig..."
    make LLVM=$LLVM_VERSION olddefconfig
    echo "[+] Generated headers created"
fi

./scripts/config --disable HYPERV
./scripts/config --disable ANDROID_BINDER_IPC
./scripts/config --disable ANDROID_BINDERFS
./scripts/config --disable IKHEADERS   

# Backup current config
cp .config .config.backup.$(date +%Y%m%d_%H%M%S)
echo "[+] Backed up current .config"

#######################################
# ENSURE MODULE SUPPORT IS ENABLED
#######################################
echo "[*] Ensuring module support is enabled..."
./scripts/config --enable MODULES
./scripts/config --enable MODULE_UNLOAD

#######################################
# PCI SUBSYSTEM (required for all hardware!)
#######################################
echo "[*] Enabling PCI subsystem..."
./scripts/config --enable PCI
./scripts/config --enable PCI_MSI

#######################################
# STORAGE DRIVERS (NVMe required for boot!)
#######################################
echo "[*] Enabling NVMe storage driver..."
./scripts/config --enable BLK_DEV_NVME

#######################################
# CPU-SPECIFIC OPTIMIZATIONS
#######################################
echo "[*] Enabling native CPU optimizations..."
./scripts/config --enable X86_NATIVE_CPU

#######################################
# LTO (Link Time Optimization)
#######################################
echo "[*] Enabling Clang ThinLTO..."
./scripts/config --disable LTO_NONE
./scripts/config --enable LTO_CLANG_THIN

#######################################
# COMPILER OPTIMIZATION
#######################################
# Use -O2 (CC_OPTIMIZE_FOR_PERFORMANCE) for best balance of
# performance and stability. This is the kernel default.
#
# Note: CC_OPTIMIZE_FOR_PERFORMANCE_O3 (-O3) is NOT available in
# kernel 6.18. The mainline kernel only supports -O2 and -Os.
# -O3 can be forced via KCFLAGS but is not recommended as:
#   - Larger kernel image causes more icache pressure
#   - Risk of compiler-induced bugs
#   - Marginal benefit for kernel workloads
#
# If you want to experiment with -O3, add to make command:
#   make KCFLAGS="-O3" LLVM=-19 -j$(nproc)
echo "[*] Using -O2 optimization (kernel default, best stability)..."
./scripts/config --enable CC_OPTIMIZE_FOR_PERFORMANCE
./scripts/config --disable CC_OPTIMIZE_FOR_SIZE

#######################################
# INITRAMFS DECOMPRESSION SUPPORT
#######################################
echo "[*] Enabling initramfs decompression..."
./scripts/config --enable BLK_DEV_INITRD
./scripts/config --enable RD_GZIP
./scripts/config --enable RD_ZSTD

#######################################
# DISABLE ALL CPU VULNERABILITY MITIGATIONS
#######################################
echo "[*] Disabling CPU vulnerability mitigations..."
./scripts/config --disable MITIGATION_PAGE_TABLE_ISOLATION
./scripts/config --disable MITIGATION_RETPOLINE
./scripts/config --disable MITIGATION_IBPB_ENTRY
./scripts/config --disable MITIGATION_IBRS_ENTRY
./scripts/config --disable MITIGATION_SLS
./scripts/config --disable MITIGATION_GDS
./scripts/config --disable MITIGATION_RFDS
./scripts/config --disable MITIGATION_SPECTRE_BHI
./scripts/config --disable MITIGATION_MDS
./scripts/config --disable MITIGATION_TAA
./scripts/config --disable MITIGATION_MMIO_STALE_DATA
./scripts/config --disable MITIGATION_L1TF
./scripts/config --disable MITIGATION_SPECTRE_V1
./scripts/config --disable MITIGATION_SPECTRE_V2
./scripts/config --disable MITIGATION_SRBDS
./scripts/config --disable MITIGATION_SSB
./scripts/config --disable MITIGATION_TSA
./scripts/config --disable MITIGATION_VMSCAPE

#######################################
# DISABLE DEBUG OPTIONS
#######################################
echo "[*] Disabling debug options..."
./scripts/config --disable DEBUG_KERNEL
./scripts/config --disable DEBUG_INFO
./scripts/config --enable DEBUG_INFO_NONE
./scripts/config --disable DEBUG_BUGVERBOSE
./scripts/config --disable SCHED_DEBUG
./scripts/config --disable DEBUG_PREEMPT

# Disable tracing/profiling
./scripts/config --disable FTRACE
./scripts/config --disable FUNCTION_TRACER
./scripts/config --disable STACK_TRACER
./scripts/config --disable TRACING
./scripts/config --disable KPROBES
./scripts/config --disable PROFILING

# Disable kernel sanitizers
./scripts/config --disable KASAN
./scripts/config --disable UBSAN
./scripts/config --disable KCSAN
./scripts/config --disable KFENCE
./scripts/config --disable KMEMLEAK
./scripts/config --disable KMSAN

# Disable lock debugging
./scripts/config --disable LOCKDEP
./scripts/config --disable PROVE_LOCKING
./scripts/config --disable DEBUG_LOCK_ALLOC
./scripts/config --disable DEBUG_LOCKDEP
./scripts/config --disable DEBUG_ATOMIC_SLEEP
./scripts/config --disable DEBUG_MUTEXES
./scripts/config --disable DEBUG_SPINLOCK
./scripts/config --disable DEBUG_RWSEMS

# Disable more kernel debugging
./scripts/config --disable DEBUG_LIST
./scripts/config --disable DEBUG_SG
./scripts/config --disable DEBUG_NOTIFIERS
./scripts/config --disable DEBUG_CREDENTIALS
./scripts/config --disable DEBUG_OBJECTS
./scripts/config --disable DEBUG_SLAB
./scripts/config --disable SLUB_DEBUG
./scripts/config --disable DEBUG_VM
./scripts/config --disable DEBUG_VIRTUAL
./scripts/config --disable DEBUG_MEMORY_INIT
./scripts/config --disable DEBUG_PER_CPU_MAPS
./scripts/config --disable DEBUG_SHIRQ
./scripts/config --disable DEBUG_STACKOVERFLOW
./scripts/config --disable DEBUG_TIMEKEEPING
./scripts/config --disable DEBUG_KOBJECT
./scripts/config --disable DEBUG_WQ_FORCE_RR_CPU
./scripts/config --disable DEBUG_BLOCK_EXT_DEVT
./scripts/config --disable DEBUG_FORCE_WEAK_PER_CPU
./scripts/config --disable DEBUG_RSEQ
./scripts/config --disable DEBUG_IRQFLAGS

# Disable RCU debugging
./scripts/config --disable RCU_TRACE
./scripts/config --disable RCU_EQS_DEBUG
./scripts/config --disable PROVE_RCU

# Disable more tracing/profiling
./scripts/config --disable FUNCTION_GRAPH_TRACER
./scripts/config --disable SCHED_TRACER
./scripts/config --disable HWLAT_TRACER
./scripts/config --disable OSNOISE_TRACER
./scripts/config --disable TIMERLAT_TRACER
./scripts/config --disable IRQSOFF_TRACER
./scripts/config --disable PREEMPTIRQ_TRACEPOINTS
./scripts/config --disable BLK_DEV_IO_TRACE
./scripts/config --disable UPROBE_EVENTS
./scripts/config --disable BPF_KPROBE_OVERRIDE
./scripts/config --disable SYNTH_EVENTS
./scripts/config --disable HIST_TRIGGERS
./scripts/config --disable TRACE_EVENT_INJECT

# Disable frame pointers (slight performance overhead)
./scripts/config --disable FRAME_POINTER

# Disable dynamic debug
./scripts/config --disable DYNAMIC_DEBUG
./scripts/config --disable DYNAMIC_DEBUG_CORE

# Disable core dump support (not needed for production, saves memory)
./scripts/config --disable COREDUMP
./scripts/config --disable ELF_CORE
./scripts/config --disable DEV_COREDUMP

# Disable Magic SysRq (emergency keys not needed, slight security/overhead)
./scripts/config --disable MAGIC_SYSRQ

# RELAY - KEEP ENABLED (required by i915 GPU driver)
# Although relay is used by tracing, i915 also uses it for GPU error capture.
# Disabling this will silently prevent DRM_I915 from being enabled!
# ./scripts/config --disable RELAY
./scripts/config --enable RELAY

# Disable kernel symbol table (debugging aid, adds kernel size)
./scripts/config --disable KALLSYMS

# Disable in-kernel headers (used by BPF CO-RE, not needed)
./scripts/config --disable IKHEADERS

# Disable boot-time memory testing (slows boot, only for diagnostics)
./scripts/config --disable MEMTEST

#######################################
# DISABLE SECURITY HARDENING
#######################################
echo "[*] Disabling security hardening (for maximum performance)..."

# Stack protection
./scripts/config --disable STACKPROTECTOR
./scripts/config --disable STACKPROTECTOR_STRONG

# Memory hardening
./scripts/config --disable FORTIFY_SOURCE
./scripts/config --disable HARDENED_USERCOPY
./scripts/config --disable SLAB_FREELIST_RANDOM
./scripts/config --disable SLAB_FREELIST_HARDENED
./scripts/config --disable INIT_ON_ALLOC_DEFAULT_ON
./scripts/config --disable INIT_ON_FREE_DEFAULT_ON
./scripts/config --disable PAGE_POISONING
./scripts/config --disable INIT_STACK_ALL_ZERO
./scripts/config --enable INIT_STACK_NONE

# ASLR - keep enabled as it has minimal performance impact
# ./scripts/config --disable RANDOMIZE_BASE
# ./scripts/config --disable RANDOMIZE_MEMORY

# Disable memory protection (slight performance gain)
./scripts/config --disable RANDOMIZE_KSTACK_OFFSET_DEFAULT

# Zero registers on function return (security feature, slight overhead)
./scripts/config --disable ZERO_CALL_USED_REGS

#######################################
# DISABLE VIRTUALIZATION GUEST OVERHEAD
#######################################
echo "[*] Disabling virtualization guest support (bare metal)..."

# Hypervisor guest support - not needed on bare metal
./scripts/config --disable HYPERVISOR_GUEST
./scripts/config --disable PARAVIRT
./scripts/config --disable PARAVIRT_XXL
./scripts/config --disable PARAVIRT_SPINLOCKS
./scripts/config --disable KVM_GUEST
./scripts/config --disable XEN
./scripts/config --disable XEN_PV
./scripts/config --disable XEN_PVHVM
./scripts/config --disable XEN_512GB
./scripts/config --disable XEN_PVH

# Disable KVM (not needed, only using Docker containers)
./scripts/config --disable VIRTUALIZATION
./scripts/config --disable KVM
./scripts/config --disable KVM_INTEL
./scripts/config --disable KVM_AMD

#######################################
# DISABLE AUDIT SUBSYSTEM
#######################################
echo "[*] Disabling audit subsystem..."
./scripts/config --disable AUDIT
./scripts/config --disable AUDITSYSCALL

#######################################
# DISABLE SECURITY FRAMEWORKS
#######################################
echo "[*] Disabling security frameworks..."
./scripts/config --disable SECURITY_SELINUX
./scripts/config --disable SECURITY_APPARMOR

# SECCOMP (Secure Computing Mode) - KEEP ENABLED for Docker compatibility
# -------------------------------------------------------------------------
# What it does: SECCOMP filters system calls that processes can make.
# Docker uses SECCOMP by default to restrict containers to ~300 of ~435 syscalls.
#
# PERFORMANCE vs COMPATIBILITY TRADE-OFF:
# ========================================
# Keeping SECCOMP enabled:
#   + Docker containers work out-of-the-box with default settings
#   + ~1-2% overhead on syscall-heavy workloads (negligible for most apps)
#   + Modern kernels use optimized BPF-based filtering
#   - Slightly more kernel code paths active
#
# Disabling SECCOMP:
#   + Eliminates syscall filtering overhead entirely
#   + Smaller kernel attack surface (paradoxically)
#   - BREAKS Docker default behavior - containers will fail to start!
#   - Requires runtime workarounds for every container
#
# RUNTIME WORKAROUNDS if SECCOMP is disabled:
# ===========================================
# Option 1: Per-container flag
#   docker run --security-opt seccomp=unconfined <image>
#
# Option 2: Global Docker daemon config (/etc/docker/daemon.json)
#   {
#     "seccomp-profile": "unconfined"
#   }
#   Then: sudo systemctl restart docker
#
# Option 3: Docker Compose (per service)
#   services:
#     myapp:
#       security_opt:
#         - seccomp:unconfined
#
# WARNING: Disabling SECCOMP reduces container isolation. All containers
# will have unrestricted syscall access. Only do this on single-user
# machines where container security is not a concern.
#
# RECOMMENDATION: Keep SECCOMP enabled. The performance gain from disabling
# is marginal (~1-2%) and not worth the Docker compatibility issues.
#
# ./scripts/config --disable SECCOMP
# ./scripts/config --disable SECCOMP_FILTER

#######################################
# DISABLE MODULE SIGNING (faster load)
#######################################
echo "[*] Disabling module signing..."
./scripts/config --disable MODULE_SIG
./scripts/config --disable MODULE_SIG_ALL
./scripts/config --disable MODVERSIONS
./scripts/config --disable MODULE_SRCVERSION_ALL

# Clear Ubuntu/Canonical certificate paths (don't exist in upstream kernel)
./scripts/config --set-str SYSTEM_TRUSTED_KEYS ""
./scripts/config --set-str SYSTEM_REVOCATION_KEYS ""

#######################################
# DISABLE POWER MANAGEMENT DEBUG
#######################################
echo "[*] Disabling power management debug..."
./scripts/config --disable PM_DEBUG
./scripts/config --disable PM_ADVANCED_DEBUG
./scripts/config --disable PM_SLEEP_DEBUG
./scripts/config --disable PM_TRACE
./scripts/config --disable PM_TRACE_RTC
./scripts/config --disable ACPI_DEBUGGER

#######################################
# DISABLE SCHEDULER DEBUG/STATS
#######################################
echo "[*] Disabling scheduler debug options..."
./scripts/config --disable SCHED_STACK_END_CHECK
./scripts/config --disable SCHED_INFO
./scripts/config --disable SCHEDSTATS
./scripts/config --disable LATENCYTOP

#######################################
# DISABLE PRINTK OVERHEAD
#######################################
echo "[*] Disabling printk overhead..."
./scripts/config --disable PRINTK_TIME
./scripts/config --disable PRINTK_CALLER
./scripts/config --disable SYMBOLIC_ERRNAME

#######################################
# DISABLE I915 GPU DEBUG/ERROR CAPTURE
#######################################
echo "[*] Disabling i915 error capture..."
./scripts/config --disable DRM_I915_CAPTURE_ERROR
./scripts/config --disable DRM_I915_COMPRESS_ERROR

#######################################
# EFI BOOT SUPPORT (required for UEFI systems)
#######################################
echo "[*] Enabling EFI boot support..."
./scripts/config --enable EFI
./scripts/config --enable EFI_STUB
./scripts/config --enable FB_EFI            # Early framebuffer before i915 loads

#######################################
# INTEL GPU (i915 for HD Graphics 620)
#######################################
echo "[*] Enabling Intel i915 GPU driver..."
./scripts/config --enable INTEL_GTT               # Intel Graphics Translation Table (required by i915)
./scripts/config --enable ACPI_WMI                # WMI (required by i915 on ACPI systems)
./scripts/config --enable DRM_I915
./scripts/config --enable BACKLIGHT_CLASS_DEVICE  # Laptop backlight control
./scripts/config --enable ACPI_VIDEO              # ACPI video extensions

#######################################
# DISPLAYLINK / USB DISPLAY CONFIGURATION
#######################################
echo "[*] Configuring DisplayLink support..."

# EVDI needs I2C for DDC/EDID communication
./scripts/config --enable I2C
./scripts/config --enable I2C_ALGOBIT

# EVDI needs USB core for hotplug notifications
./scripts/config --enable USB
./scripts/config --enable USB_SUPPORT

# EVDI needs DRM with atomic modesetting helpers
./scripts/config --enable DRM
./scripts/config --enable DRM_KMS_HELPER
./scripts/config --enable DRM_GEM_SHMEM_HELPER
./scripts/config --enable DRM_FBDEV_EMULATION

# DRM dependencies
./scripts/config --enable FB
./scripts/config --enable FB_CORE
./scripts/config --enable FB_SYSMEM_HELPERS
./scripts/config --enable FB_SYSMEM_HELPERS_DEFERRED
./scripts/config --enable FRAMEBUFFER_CONSOLE
./scripts/config --enable DMA_SHARED_BUFFER
./scripts/config --enable SYNC_FILE

# DRM_EVDI - DO NOT DISABLE - Built out-of-tree from github.com/DisplayLink/evdi
# The in-kernel DRM_EVDI option is for the staging driver, but we build the
# official DisplayLink evdi module separately (see BUILD EVDI MODULE section).
# Disabling the staging driver prevents conflicts with our out-of-tree module.
# Note: DRM core support (DRM, DRM_KMS_HELPER) must remain enabled.

# DRM_SIMPLEDRM - Enables FB_SYS_* symbols required for evdi module
# This driver selects DRM_GEM_SHMEM_HELPER which (with DRM_FBDEV_EMULATION=y)
# chains to FB_SYSMEM_HELPERS -> FB_SYS_FILLRECT/COPYAREA/IMAGEBLIT.
# These provide sys_fillrect, sys_copyarea, sys_imageblit that evdi needs.
# DRM_SIMPLEDRM is also useful for early boot framebuffer console.
./scripts/config --module DRM_SIMPLEDRM

# Legacy DisplayLink drivers - safe to disable (replaced by EVDI)
./scripts/config --disable FB_UDLFB      # Legacy USB framebuffer - not needed
./scripts/config --disable USB_UDL       # Legacy USB DisplayLink - not needed
./scripts/config --disable DRM_UDL       # Legacy DRM DisplayLink - not needed

#######################################
# DISABLE UNUSED GPU DRIVERS
#######################################
echo "[*] Disabling unused GPU drivers (keeping i915 only)..."
./scripts/config --disable DRM_NOUVEAU
./scripts/config --disable DRM_AMDGPU
./scripts/config --disable DRM_RADEON
./scripts/config --disable DRM_VMWGFX
./scripts/config --disable DRM_QXL
./scripts/config --disable DRM_VIRTIO_GPU
./scripts/config --disable DRM_BOCHS
./scripts/config --disable DRM_CIRRUS_QEMU
./scripts/config --disable DRM_AST
./scripts/config --disable DRM_MGAG200

#######################################
# DISABLE UNUSED WIFI VENDORS (keep Atheros only)
#######################################
echo "[*] Disabling unused WiFi vendors..."
./scripts/config --disable WLAN_VENDOR_ADMTEK
./scripts/config --disable WLAN_VENDOR_ATMEL
./scripts/config --disable WLAN_VENDOR_BROADCOM
./scripts/config --disable WLAN_VENDOR_INTEL
./scripts/config --disable WLAN_VENDOR_INTERSIL
./scripts/config --disable WLAN_VENDOR_MARVELL
./scripts/config --disable WLAN_VENDOR_MEDIATEK
./scripts/config --disable WLAN_VENDOR_MICROCHIP
./scripts/config --disable WLAN_VENDOR_PURELIFI
./scripts/config --disable WLAN_VENDOR_RALINK
./scripts/config --disable WLAN_VENDOR_REALTEK
./scripts/config --disable WLAN_VENDOR_RSI
./scripts/config --disable WLAN_VENDOR_SILABS
./scripts/config --disable WLAN_VENDOR_ST
./scripts/config --disable WLAN_VENDOR_TI
./scripts/config --disable WLAN_VENDOR_ZYDAS
./scripts/config --disable WLAN_VENDOR_QUANTENNA

#######################################
# DISABLE UNUSED ETHERNET VENDORS
#######################################
echo "[*] Disabling unused Ethernet vendors..."
./scripts/config --disable NET_VENDOR_3COM
./scripts/config --disable NET_VENDOR_ADAPTEC
./scripts/config --disable NET_VENDOR_AGERE
./scripts/config --disable NET_VENDOR_ALACRITECH
./scripts/config --disable NET_VENDOR_ALTEON
./scripts/config --disable NET_VENDOR_AMAZON
./scripts/config --disable NET_VENDOR_AMD
./scripts/config --disable NET_VENDOR_AQUANTIA
./scripts/config --disable NET_VENDOR_ARC
./scripts/config --disable NET_VENDOR_ASIX
./scripts/config --disable NET_VENDOR_ATHEROS
./scripts/config --disable NET_VENDOR_BROADCOM
./scripts/config --disable NET_VENDOR_CADENCE
./scripts/config --disable NET_VENDOR_CAVIUM
./scripts/config --disable NET_VENDOR_CHELSIO
./scripts/config --disable NET_VENDOR_CISCO
./scripts/config --disable NET_VENDOR_CORTINA
./scripts/config --disable NET_VENDOR_DAVICOM
./scripts/config --disable NET_VENDOR_DEC
./scripts/config --disable NET_VENDOR_DLINK
./scripts/config --disable NET_VENDOR_EMULEX
./scripts/config --disable NET_VENDOR_ENGLEDER
./scripts/config --disable NET_VENDOR_EZCHIP
./scripts/config --disable NET_VENDOR_FUNGIBLE
./scripts/config --disable NET_VENDOR_GOOGLE
./scripts/config --disable NET_VENDOR_HUAWEI
./scripts/config --disable NET_VENDOR_INTEL
./scripts/config --disable NET_VENDOR_LITEX
./scripts/config --disable NET_VENDOR_MARVELL
./scripts/config --disable NET_VENDOR_MELLANOX
./scripts/config --disable NET_VENDOR_MICREL
./scripts/config --disable NET_VENDOR_MICROCHIP
./scripts/config --disable NET_VENDOR_MICROSEMI
./scripts/config --disable NET_VENDOR_MICROSOFT
./scripts/config --disable NET_VENDOR_MYRI
./scripts/config --disable NET_VENDOR_NATSEMI
./scripts/config --disable NET_VENDOR_NETERION
./scripts/config --disable NET_VENDOR_NETRONOME
./scripts/config --disable NET_VENDOR_NI
./scripts/config --disable NET_VENDOR_NVIDIA
./scripts/config --disable NET_VENDOR_OKI
./scripts/config --disable NET_VENDOR_PACKET_ENGINES
./scripts/config --disable NET_VENDOR_PENSANDO
./scripts/config --disable NET_VENDOR_QLOGIC
./scripts/config --disable NET_VENDOR_BROCADE
./scripts/config --disable NET_VENDOR_QUALCOMM
./scripts/config --disable NET_VENDOR_RDC
./scripts/config --disable NET_VENDOR_REALTEK
./scripts/config --disable NET_VENDOR_RENESAS
./scripts/config --disable NET_VENDOR_ROCKER
./scripts/config --disable NET_VENDOR_SAMSUNG
./scripts/config --disable NET_VENDOR_SEEQ
./scripts/config --disable NET_VENDOR_SILAN
./scripts/config --disable NET_VENDOR_SIS
./scripts/config --disable NET_VENDOR_SMSC
./scripts/config --disable NET_VENDOR_SOCIONEXT
./scripts/config --disable NET_VENDOR_SOLARFLARE
./scripts/config --disable NET_VENDOR_STMICRO
./scripts/config --disable NET_VENDOR_SUN
./scripts/config --disable NET_VENDOR_SYNOPSYS
./scripts/config --disable NET_VENDOR_TEHUTI
./scripts/config --disable NET_VENDOR_TI
./scripts/config --disable NET_VENDOR_VERTEXCOM
./scripts/config --disable NET_VENDOR_VIA
./scripts/config --disable NET_VENDOR_WANGXUN
./scripts/config --disable NET_VENDOR_WIZNET
./scripts/config --disable NET_VENDOR_XILINX
./scripts/config --disable FDDI
./scripts/config --disable HIPPI
./scripts/config --disable NET_SB1000

#######################################
# DISABLE OBSOLETE/UNUSED SUBSYSTEMS
#######################################
echo "[*] Disabling obsolete/unused subsystems..."
./scripts/config --disable HAMRADIO
./scripts/config --disable ISDN
./scripts/config --disable WIMAX
./scripts/config --disable CAN
./scripts/config --disable NFC
./scripts/config --disable INFINIBAND
./scripts/config --disable CAIF
./scripts/config --disable HSR
./scripts/config --disable PHONET
./scripts/config --disable IEEE802154
./scripts/config --disable 6LOWPAN
./scripts/config --disable ATM
./scripts/config --disable DECNET
./scripts/config --disable LAPB
./scripts/config --disable X25

#######################################
# DISABLE UNUSED INPUT DEVICES
#######################################
echo "[*] Disabling unused input devices..."
./scripts/config --disable INPUT_JOYSTICK
./scripts/config --disable INPUT_TABLET
./scripts/config --disable INPUT_JOYDEV
./scripts/config --disable GAMEPORT

#######################################
# DISABLE UNUSED HID DRIVERS (keep core + Dell essentials)
#######################################
echo "[*] Disabling unused HID vendor drivers..."
# Keep: HID core, generic, multitouch, i2c-hid, usbhid
# Keep: Alps, Elan, RMI (Synaptics) - common Dell touchpads

# Gaming peripherals - not needed
./scripts/config --disable HID_ACRUX
./scripts/config --disable HID_BIGBEN
./scripts/config --disable HID_BETOP
./scripts/config --disable HID_COUGAR
./scripts/config --disable HID_CORSAIR
./scripts/config --disable HID_CREATIVE_SB0540
./scripts/config --disable HID_DRAGONRISE
./scripts/config --disable HID_GLORIOUS
./scripts/config --disable HID_GOOGLE_STADIA
./scripts/config --disable HID_GT683R
./scripts/config --disable HID_HOLTEK
./scripts/config --disable HID_LOGITECH
./scripts/config --disable HID_LOGITECH_DJ
./scripts/config --disable HID_LOGITECH_HIDPP
./scripts/config --disable HID_NINTENDO
./scripts/config --disable HID_PLAYSTATION
./scripts/config --disable HID_RAZER
./scripts/config --disable HID_REDRAGON
./scripts/config --disable HID_ROCCAT
./scripts/config --disable HID_SAITEK
./scripts/config --disable HID_SONY
./scripts/config --disable HID_SPEEDLINK
./scripts/config --disable HID_STEAM
./scripts/config --disable HID_STEELSERIES
./scripts/config --disable HID_THRUSTMASTER
./scripts/config --disable HID_WINWING
./scripts/config --disable HID_ZEROPLUS

# Other vendor HID - not Dell
./scripts/config --disable HID_A4TECH
./scripts/config --disable HID_APPLE
./scripts/config --disable HID_APPLEIR
./scripts/config --disable HID_APPLETB_BL
./scripts/config --disable HID_APPLETB_KBD
./scripts/config --disable HID_ASUS
./scripts/config --disable HID_AUREAL
./scripts/config --disable HID_BELKIN
./scripts/config --disable HID_CMEDIA
./scripts/config --disable HID_CYPRESS
./scripts/config --disable HID_ELECOM
./scripts/config --disable HID_ELO
./scripts/config --disable HID_EVISION
./scripts/config --disable HID_EZKEY
./scripts/config --disable HID_GEMBIRD
./scripts/config --disable HID_GFRM
./scripts/config --disable HID_GOODIX_SPI
./scripts/config --disable HID_GOOGLE_HAMMER
./scripts/config --disable HID_GYRATION
./scripts/config --disable HID_HYPERV
./scripts/config --disable HID_ICADE
./scripts/config --disable HID_ITE
./scripts/config --disable HID_JABRA
./scripts/config --disable HID_KENSINGTON
./scripts/config --disable HID_KEYTOUCH
./scripts/config --disable HID_KYE
./scripts/config --disable HID_KYSONA
./scripts/config --disable HID_LCPOWER
./scripts/config --disable HID_LENOVO
./scripts/config --disable HID_LETSKETCH
./scripts/config --disable HID_MACALLY
./scripts/config --disable HID_MAGICMOUSE
./scripts/config --disable HID_MALTRON
./scripts/config --disable HID_MCP2221
./scripts/config --disable HID_MEGAWORLD
./scripts/config --disable HID_MICROSOFT
./scripts/config --disable HID_MONTEREY
./scripts/config --disable HID_NTI
./scripts/config --disable HID_NTRIG
./scripts/config --disable HID_NVIDIA_SHIELD
./scripts/config --disable HID_ORTEK
./scripts/config --disable HID_PENMOUNT
./scripts/config --disable HID_PETALYNX
./scripts/config --disable HID_PICOLCD
./scripts/config --disable HID_PLANTRONICS
./scripts/config --disable HID_PRIMAX
./scripts/config --disable HID_PRODIKEYS
./scripts/config --disable HID_RETRODE
./scripts/config --disable HID_SAMSUNG
./scripts/config --disable HID_SEMITEK
./scripts/config --disable HID_SIGMAMICRO
./scripts/config --disable HID_SMARTJOYPLUS
./scripts/config --disable HID_SUNPLUS
./scripts/config --disable HID_TIVO
./scripts/config --disable HID_TOPSEED
./scripts/config --disable HID_TWINHAN
./scripts/config --disable HID_U2FZERO
./scripts/config --disable HID_UCLOGIC
./scripts/config --disable HID_UDRAW_PS3
./scripts/config --disable HID_VIEWSONIC
./scripts/config --disable HID_VRC2
./scripts/config --disable HID_WALTOP
./scripts/config --disable HID_WIIMOTE
./scripts/config --disable HID_XIAOMI
./scripts/config --disable HID_XINMO
./scripts/config --disable HID_ZYDACRON

# Wacom tablets - not needed
./scripts/config --disable HID_WACOM

#######################################
# DISABLE LEGACY PORTS
#######################################
echo "[*] Disabling legacy ports..."
./scripts/config --disable PARPORT
./scripts/config --disable PCMCIA
./scripts/config --disable FIREWIRE

#######################################
# DISABLE UNUSED MEDIA/DVB DRIVERS
#######################################
echo "[*] Disabling unused media drivers..."
./scripts/config --disable DVB_CORE
./scripts/config --disable MEDIA_ANALOG_TV_SUPPORT
./scripts/config --disable MEDIA_DIGITAL_TV_SUPPORT
./scripts/config --disable MEDIA_RADIO_SUPPORT
./scripts/config --disable MEDIA_SDR_SUPPORT
./scripts/config --disable MEDIA_TEST_SUPPORT
./scripts/config --disable MEDIA_PLATFORM_SUPPORT

#######################################
# DISABLE ARM/EMBEDDED SOC DRIVERS (x86 laptop only)
#######################################
echo "[*] Disabling ARM/embedded SoC drivers..."
# ARM SoC vendors - not needed on x86
./scripts/config --disable ARCH_SUNXI
./scripts/config --disable ARCH_ALPINE
./scripts/config --disable ARCH_APPLE
./scripts/config --disable ARCH_BCM
./scripts/config --disable ARCH_BERLIN
./scripts/config --disable ARCH_EXYNOS
./scripts/config --disable ARCH_K3
./scripts/config --disable ARCH_LG1K
./scripts/config --disable ARCH_HISI
./scripts/config --disable ARCH_MEDIATEK
./scripts/config --disable ARCH_MESON
./scripts/config --disable ARCH_MVEBU
./scripts/config --disable ARCH_NXP
./scripts/config --disable ARCH_QCOM
./scripts/config --disable ARCH_ROCKCHIP
./scripts/config --disable ARCH_RENESAS
./scripts/config --disable ARCH_S32
./scripts/config --disable ARCH_INTEL_SOCFPGA
./scripts/config --disable ARCH_STM32
./scripts/config --disable ARCH_TEGRA
./scripts/config --disable ARCH_SPRD
./scripts/config --disable ARCH_THUNDER
./scripts/config --disable ARCH_UNIPHIER
./scripts/config --disable ARCH_VEXPRESS
./scripts/config --disable ARCH_ZYNQMP

# SoC-specific platform drivers
./scripts/config --disable SOC_SAMSUNG
./scripts/config --disable SOC_TI

# Media platform drivers for embedded SoCs
./scripts/config --disable VIDEO_SAMSUNG_S5P_G2D
./scripts/config --disable VIDEO_SAMSUNG_S5P_JPEG
./scripts/config --disable VIDEO_SAMSUNG_S5P_MFC
./scripts/config --disable VIDEO_SAMSUNG_EXYNOS_GSC
./scripts/config --disable V4L_PLATFORM_DRIVERS
./scripts/config --disable V4L_MEM2MEM_DRIVERS

# Embedded/SoC DRM drivers
./scripts/config --disable DRM_EXYNOS
./scripts/config --disable DRM_ROCKCHIP
./scripts/config --disable DRM_TEGRA
./scripts/config --disable DRM_STM
./scripts/config --disable DRM_MESON
./scripts/config --disable DRM_MEDIATEK
./scripts/config --disable DRM_LIMA
./scripts/config --disable DRM_PANFROST
./scripts/config --disable DRM_ETNAVIV
./scripts/config --disable DRM_HISI_HIBMC
./scripts/config --disable DRM_HISI_KIRIN

# Embedded USB/PHY drivers
./scripts/config --disable PHY_SAMSUNG_USB2
./scripts/config --disable PHY_EXYNOS_DP_VIDEO
./scripts/config --disable PHY_EXYNOS_MIPI_VIDEO

# ARM-specific kernel features
./scripts/config --disable ARM_SCMI_PROTOCOL
./scripts/config --disable ARM_SCPI_PROTOCOL
./scripts/config --disable RASPBERRYPI_FIRMWARE
./scripts/config --disable RASPBERRYPI_POWER

# Embedded clocks/pinctrl (not needed on x86)
./scripts/config --disable PINCTRL_SAMSUNG
./scripts/config --disable PINCTRL_EXYNOS

#######################################
# DISABLE EMBEDDED CLOCK DRIVERS
#######################################
echo "[*] Disabling embedded clock drivers..."
# All embedded SoC clock drivers - not needed on x86
./scripts/config --disable COMMON_CLK_SAMSUNG
./scripts/config --disable COMMON_CLK_ACTIONS
./scripts/config --disable COMMON_CLK_AMLOGIC
./scripts/config --disable COMMON_CLK_ASPEED
./scripts/config --disable COMMON_CLK_AT91
./scripts/config --disable COMMON_CLK_AXI_CLKGEN
./scripts/config --disable COMMON_CLK_BCM
./scripts/config --disable COMMON_CLK_BERLIN
./scripts/config --disable COMMON_CLK_CDCE706
./scripts/config --disable COMMON_CLK_CDCE925
./scripts/config --disable COMMON_CLK_CS2000_CP
./scripts/config --disable COMMON_CLK_FSL_FLEXSPI
./scripts/config --disable COMMON_CLK_FSL_SAI
./scripts/config --disable COMMON_CLK_GEMINI
./scripts/config --disable COMMON_CLK_HI3516CV300
./scripts/config --disable COMMON_CLK_HI3519
./scripts/config --disable COMMON_CLK_HI3559A
./scripts/config --disable COMMON_CLK_HI3660
./scripts/config --disable COMMON_CLK_HI3670
./scripts/config --disable COMMON_CLK_HI3798CV200
./scripts/config --disable COMMON_CLK_HI6220
./scripts/config --disable COMMON_CLK_IPROC
./scripts/config --disable COMMON_CLK_KEYSTONE
./scripts/config --disable COMMON_CLK_LOCHNAGAR
./scripts/config --disable COMMON_CLK_MEDIATEK
./scripts/config --disable COMMON_CLK_MESON
./scripts/config --disable COMMON_CLK_MICROCHIP
./scripts/config --disable COMMON_CLK_MMP2
./scripts/config --disable COMMON_CLK_MT6765
./scripts/config --disable COMMON_CLK_MT6779
./scripts/config --disable COMMON_CLK_MT6795
./scripts/config --disable COMMON_CLK_MT7622
./scripts/config --disable COMMON_CLK_MT7629
./scripts/config --disable COMMON_CLK_MT7986
./scripts/config --disable COMMON_CLK_MT8135
./scripts/config --disable COMMON_CLK_MT8167
./scripts/config --disable COMMON_CLK_MT8173
./scripts/config --disable COMMON_CLK_MT8183
./scripts/config --disable COMMON_CLK_MT8186
./scripts/config --disable COMMON_CLK_MT8188
./scripts/config --disable COMMON_CLK_MT8192
./scripts/config --disable COMMON_CLK_MT8195
./scripts/config --disable COMMON_CLK_NXP
./scripts/config --disable COMMON_CLK_OXNAS
./scripts/config --disable COMMON_CLK_PALMAS
./scripts/config --disable COMMON_CLK_PWM
./scripts/config --disable COMMON_CLK_PXA
./scripts/config --disable COMMON_CLK_QCOM
./scripts/config --disable COMMON_CLK_RK808
./scripts/config --disable COMMON_CLK_ROCKCHIP
./scripts/config --disable COMMON_CLK_S2MPS11
./scripts/config --disable COMMON_CLK_SCMI
./scripts/config --disable COMMON_CLK_SCPI
./scripts/config --disable COMMON_CLK_SI5341
./scripts/config --disable COMMON_CLK_SI5351
./scripts/config --disable COMMON_CLK_SI514
./scripts/config --disable COMMON_CLK_SI544
./scripts/config --disable COMMON_CLK_SI570
./scripts/config --disable COMMON_CLK_SOPHGO_CV1800
./scripts/config --disable COMMON_CLK_STM32F
./scripts/config --disable COMMON_CLK_STM32H7
./scripts/config --disable COMMON_CLK_STM32MP
./scripts/config --disable COMMON_CLK_SUNXI
./scripts/config --disable COMMON_CLK_TEGRA
./scripts/config --disable COMMON_CLK_TI_ADPLL
./scripts/config --disable COMMON_CLK_VC5
./scripts/config --disable COMMON_CLK_VISCONTI
./scripts/config --disable COMMON_CLK_XGENE
./scripts/config --disable COMMON_CLK_ZYNQMP

# Clock driver vendor directories
./scripts/config --disable CLK_ACTIONS
./scripts/config --disable CLK_BAIKAL_T1
./scripts/config --disable CLK_BCM2711_DVP
./scripts/config --disable CLK_BCM2835
./scripts/config --disable CLK_BCM_63XX
./scripts/config --disable CLK_BCM_63XX_GATE
./scripts/config --disable CLK_BCM_KONA
./scripts/config --disable CLK_BCM_NS2
./scripts/config --disable CLK_BCM_NSP
./scripts/config --disable CLK_BCM_SR
./scripts/config --disable CLK_BERLIN_BG4
./scripts/config --disable CLK_DAVINCI_DA8XX
./scripts/config --disable CLK_DAVINCI_DM355
./scripts/config --disable CLK_DAVINCI_DM365
./scripts/config --disable CLK_DAVINCI_DM644X
./scripts/config --disable CLK_DAVINCI_DM646X
./scripts/config --disable CLK_HSDK
./scripts/config --disable CLK_IMX8MM
./scripts/config --disable CLK_IMX8MN
./scripts/config --disable CLK_IMX8MP
./scripts/config --disable CLK_IMX8MQ
./scripts/config --disable CLK_INGENIC
./scripts/config --disable CLK_LS1028A
./scripts/config --disable CLK_MILBEAUT
./scripts/config --disable CLK_MSTAR
./scripts/config --disable CLK_MXS
./scripts/config --disable CLK_PISTACHIO
./scripts/config --disable CLK_RENESAS
./scripts/config --disable CLK_SIFIVE
./scripts/config --disable CLK_SPRD
./scripts/config --disable CLK_STARFIVE_JH7100
./scripts/config --disable CLK_STARFIVE_JH7110
./scripts/config --disable CLK_SUNXI_NG
./scripts/config --disable CLK_THEAD
./scripts/config --disable CLK_TI
./scripts/config --disable CLK_UNIPHIER
./scripts/config --disable CLK_ZYNQ

#######################################
# DISABLE EMBEDDED SOC DRIVERS
#######################################
echo "[*] Disabling embedded SoC drivers..."
# All embedded SoC drivers - not needed on x86
./scripts/config --disable SOC_AMLOGIC
./scripts/config --disable SOC_AMLOGIC_MESON_GX_SOCINFO
./scripts/config --disable SOC_AMLOGIC_MESON_MX_SOCINFO
./scripts/config --disable SOC_APPLE
./scripts/config --disable SOC_ASPEED
./scripts/config --disable SOC_ATMEL
./scripts/config --disable SOC_BCM
./scripts/config --disable SOC_BRCMSTB
./scripts/config --disable SOC_CANAAN
./scripts/config --disable SOC_CIRRUS
./scripts/config --disable SOC_DOVE
./scripts/config --disable SOC_FSL
./scripts/config --disable SOC_FUJITSU
./scripts/config --disable SOC_GEMINI
./scripts/config --disable SOC_HISILICON
./scripts/config --disable SOC_IMX
./scripts/config --disable SOC_IMX8M
./scripts/config --disable SOC_IXP4XX
./scripts/config --disable SOC_LANTIQ
./scripts/config --disable SOC_LITEX
./scripts/config --disable SOC_LOONGSON
./scripts/config --disable SOC_MEDIATEK
./scripts/config --disable SOC_MICROCHIP
./scripts/config --disable SOC_NUVOTON
./scripts/config --disable SOC_PXA
./scripts/config --disable SOC_QCOM
./scripts/config --disable SOC_RENESAS
./scripts/config --disable SOC_ROCKCHIP
./scripts/config --disable SOC_SAMSUNG
./scripts/config --disable SOC_SOPHGO
./scripts/config --disable SOC_SUNXI
./scripts/config --disable SOC_TEGRA
./scripts/config --disable SOC_TI
./scripts/config --disable SOC_UX500
./scripts/config --disable SOC_VERSATILE
./scripts/config --disable SOC_VT8500
./scripts/config --disable SOC_XILINX

#######################################
# DISABLE EMBEDDED/NON-X86 SUBSYSTEMS
#######################################
echo "[*] Disabling embedded/non-x86 subsystems..."

# MTD - Flash memory devices (embedded systems)
./scripts/config --disable MTD

# Memory controllers (embedded)
./scripts/config --disable MEMORY

# Regulator framework - keep enabled, some Intel drivers need it
# ./scripts/config --disable REGULATOR

# Reset controllers (embedded)
./scripts/config --disable RESET_CONTROLLER

# Mailbox (inter-processor communication, embedded)
./scripts/config --disable MAILBOX

# IOMMU - keep Intel, disable others
./scripts/config --disable AMD_IOMMU
./scripts/config --disable IRQ_REMAP

# Remote processors (embedded)
./scripts/config --disable REMOTEPROC
./scripts/config --disable RPMSG

# SoC bus drivers
./scripts/config --disable SOC_BUS

# TEE (TrustZone, ARM)
./scripts/config --disable TEE

# Generic PHY framework (mostly embedded)
./scripts/config --disable GENERIC_PHY

# Power supply - keep enabled for laptop battery
# ./scripts/config --disable POWER_SUPPLY

# Pulse Width Modulation (embedded)
./scripts/config --disable PWM

# NVMEM (embedded non-volatile memory)
./scripts/config --disable NVMEM

# FSI (IBM Power specific)
./scripts/config --disable FSI

# MUX subsystem (embedded)
./scripts/config --disable MULTIPLEXER

# Interconnect (ARM SoC)
./scripts/config --disable INTERCONNECT

# Counter subsystem (embedded)
./scripts/config --disable COUNTER

# HTE (Hardware Timestamping Engine, embedded)
./scripts/config --disable HTE

#######################################
# DISABLE USB GADGET (device mode)
#######################################
echo "[*] Disabling USB gadget/device mode..."
./scripts/config --disable USB_GADGET
./scripts/config --disable USB_CONFIGFS
./scripts/config --disable USB_MUSB_HDRC
./scripts/config --disable USB_DWC3
./scripts/config --disable USB_DWC2
./scripts/config --disable USB_CHIPIDEA

#######################################
# DISABLE SOUND DRIVERS (keep Intel HDA only)
#######################################
echo "[*] Disabling non-Intel sound drivers..."
./scripts/config --disable SND_SOC
# USB audio is required per HARDWARE_INVENTORY.md (DisplayLink dock audio, Blue Yeti mic)
./scripts/config --module SND_USB_AUDIO
./scripts/config --disable SND_FIREWIRE
./scripts/config --disable SND_PCMCIA
./scripts/config --disable SND_SPARC
./scripts/config --disable SND_SPI
./scripts/config --disable SND_MIPS
./scripts/config --disable SND_XEN_FRONTEND
./scripts/config --disable SND_VIRTIO

#######################################
# DISABLE MMC/SD HOST CONTROLLERS (except laptop slots)
#######################################
echo "[*] Disabling embedded MMC/SD controllers..."
./scripts/config --disable MMC_SDHCI_PLTFM
./scripts/config --disable MMC_SDHCI_OF_ARASAN
./scripts/config --disable MMC_SDHCI_OF_AT91
./scripts/config --disable MMC_SDHCI_CADENCE
./scripts/config --disable MMC_SDHCI_F_SDH30
./scripts/config --disable MMC_DW
./scripts/config --disable MMC_SPI
./scripts/config --disable MMC_SUNXI

#######################################
# DISABLE GPIO/PINCTRL (keep Intel only)
#######################################
echo "[*] Disabling non-Intel GPIO/pinctrl..."
./scripts/config --disable GPIO_DWAPB
./scripts/config --disable GPIO_MB86S7X
./scripts/config --disable GPIO_PL061
./scripts/config --disable GPIO_XGENE
./scripts/config --disable GPIO_XILINX
./scripts/config --disable PINCTRL_AMD
./scripts/config --disable PINCTRL_SINGLE

#######################################
# DISABLE I2C BUS DRIVERS (keep Intel only)
#######################################
echo "[*] Disabling non-Intel I2C controllers..."
./scripts/config --disable I2C_CADENCE
./scripts/config --disable I2C_DESIGNWARE_PLATFORM
./scripts/config --disable I2C_EMEV2
./scripts/config --disable I2C_GPIO
./scripts/config --disable I2C_IMX
./scripts/config --disable I2C_MV64XXX
./scripts/config --disable I2C_OCORES
./scripts/config --disable I2C_PCA_PLATFORM
./scripts/config --disable I2C_RK3X
./scripts/config --disable I2C_SIMTEC
./scripts/config --disable I2C_XILINX

#######################################
# DISABLE SPI CONTROLLERS (keep PCI only)
#######################################
echo "[*] Disabling embedded SPI controllers..."
./scripts/config --disable SPI_CADENCE
./scripts/config --disable SPI_DESIGNWARE
./scripts/config --disable SPI_DW_MMIO
./scripts/config --disable SPI_GPIO
./scripts/config --disable SPI_FSL_SPI
./scripts/config --disable SPI_OC_TINY
./scripts/config --disable SPI_ORION
./scripts/config --disable SPI_PL022
./scripts/config --disable SPI_ROCKCHIP
./scripts/config --disable SPI_XILINX

#######################################
# DISABLE RTC DRIVERS (keep PC RTC only)
#######################################
echo "[*] Disabling embedded RTC drivers..."
./scripts/config --disable RTC_DRV_ABB5ZES3
./scripts/config --disable RTC_DRV_ABEOZ9
./scripts/config --disable RTC_DRV_DS1307
./scripts/config --disable RTC_DRV_DS1374
./scripts/config --disable RTC_DRV_DS1672
./scripts/config --disable RTC_DRV_DS3232
./scripts/config --disable RTC_DRV_HYM8563
./scripts/config --disable RTC_DRV_ISL1208
./scripts/config --disable RTC_DRV_M41T80
./scripts/config --disable RTC_DRV_MAX6900
./scripts/config --disable RTC_DRV_MAX77686
./scripts/config --disable RTC_DRV_MCP795
./scripts/config --disable RTC_DRV_PALMAS
./scripts/config --disable RTC_DRV_PCF2123
./scripts/config --disable RTC_DRV_PCF2127
./scripts/config --disable RTC_DRV_PCF85063
./scripts/config --disable RTC_DRV_PCF8523
./scripts/config --disable RTC_DRV_PCF85363
./scripts/config --disable RTC_DRV_PCF8563
./scripts/config --disable RTC_DRV_RV3028
./scripts/config --disable RTC_DRV_RV3032
./scripts/config --disable RTC_DRV_RV8803
./scripts/config --disable RTC_DRV_RX8581
./scripts/config --disable RTC_DRV_S35390A
./scripts/config --disable RTC_DRV_SD3078
./scripts/config --disable RTC_DRV_BQ32K
./scripts/config --disable RTC_DRV_FM3130
./scripts/config --disable RTC_DRV_RX8025

#######################################
# DISABLE DMA ENGINES (keep Intel only)
#######################################
echo "[*] Disabling non-Intel DMA engines..."
./scripts/config --disable AMBA_PL08X
./scripts/config --disable DW_DMAC
./scripts/config --disable DW_DMAC_CORE
./scripts/config --disable FSL_DMA
./scripts/config --disable FSL_EDMA
./scripts/config --disable MV_XOR
./scripts/config --disable MV_XOR_V2
./scripts/config --disable PL330_DMA
./scripts/config --disable XILINX_DMA
./scripts/config --disable QCOM_BAM_DMA
./scripts/config --disable DMA_BCM2835

#######################################
# DISABLE NON-INTEL THERMAL DRIVERS
#######################################
echo "[*] Disabling non-Intel thermal drivers..."
./scripts/config --disable ARMADA_THERMAL
./scripts/config --disable HISI_THERMAL
./scripts/config --disable IMX_THERMAL
./scripts/config --disable MTK_THERMAL
./scripts/config --disable QCOM_TSENS
./scripts/config --disable RCAR_THERMAL
./scripts/config --disable RCAR_GEN3_THERMAL
./scripts/config --disable ROCKCHIP_THERMAL
./scripts/config --disable TEGRA_SOCTHERM
./scripts/config --disable GENERIC_ADC_THERMAL

#######################################
# DISABLE CRYPTO HW ACCELERATORS (keep Intel)
#######################################
echo "[*] Disabling non-Intel crypto accelerators..."
./scripts/config --disable CRYPTO_DEV_ATMEL_AES
./scripts/config --disable CRYPTO_DEV_ATMEL_SHA
./scripts/config --disable CRYPTO_DEV_ATMEL_TDES
./scripts/config --disable CRYPTO_DEV_FSL_CAAM
./scripts/config --disable CRYPTO_DEV_QCE
./scripts/config --disable CRYPTO_DEV_QCOM_RNG
./scripts/config --disable CRYPTO_DEV_ROCKCHIP
./scripts/config --disable CRYPTO_DEV_S5P
./scripts/config --disable CRYPTO_DEV_EXYNOS_RNG
./scripts/config --disable CRYPTO_DEV_CCREE
./scripts/config --disable CRYPTO_DEV_HISI_SEC
./scripts/config --disable CRYPTO_DEV_HISI_ZIP
./scripts/config --disable CRYPTO_DEV_AMLOGIC_GXL
./scripts/config --disable CRYPTO_DEV_SA2UL
./scripts/config --disable CRYPTO_DEV_STM32_CRC
./scripts/config --disable CRYPTO_DEV_STM32_HASH
./scripts/config --disable CRYPTO_DEV_STM32_CRYP
./scripts/config --disable CRYPTO_DEV_VIRTIO

#######################################
# DISABLE WATCHDOG (keep Intel/iTCO)
#######################################
echo "[*] Disabling non-Intel watchdogs..."
./scripts/config --disable WATCHDOG
./scripts/config --disable SOFT_WATCHDOG

#######################################
# DISABLE HWMON SENSORS (keep Intel only)
#######################################
echo "[*] Disabling non-Intel hardware monitoring..."
./scripts/config --disable SENSORS_AD7418
./scripts/config --disable SENSORS_ADM1021
./scripts/config --disable SENSORS_ADM1025
./scripts/config --disable SENSORS_ADM1026
./scripts/config --disable SENSORS_ADM1029
./scripts/config --disable SENSORS_ADM1031
./scripts/config --disable SENSORS_ADM9240
./scripts/config --disable SENSORS_ASC7621
./scripts/config --disable SENSORS_ASPEED
./scripts/config --disable SENSORS_DS1621
./scripts/config --disable SENSORS_F71805F
./scripts/config --disable SENSORS_GL518SM
./scripts/config --disable SENSORS_GL520SM
./scripts/config --disable SENSORS_G760A
./scripts/config --disable SENSORS_GPIO_FAN
./scripts/config --disable SENSORS_HIH6130
./scripts/config --disable SENSORS_INA209
./scripts/config --disable SENSORS_INA2XX
./scripts/config --disable SENSORS_INA3221
./scripts/config --disable SENSORS_IT87
./scripts/config --disable SENSORS_JC42
./scripts/config --disable SENSORS_LM63
./scripts/config --disable SENSORS_LM75
./scripts/config --disable SENSORS_LM77
./scripts/config --disable SENSORS_LM78
./scripts/config --disable SENSORS_LM80
./scripts/config --disable SENSORS_LM83
./scripts/config --disable SENSORS_LM85
./scripts/config --disable SENSORS_LM87
./scripts/config --disable SENSORS_LM90
./scripts/config --disable SENSORS_LM92
./scripts/config --disable SENSORS_LM93
./scripts/config --disable SENSORS_LM95234
./scripts/config --disable SENSORS_LM95245
./scripts/config --disable SENSORS_MAX1111
./scripts/config --disable SENSORS_MAX16065
./scripts/config --disable SENSORS_MAX1619
./scripts/config --disable SENSORS_MAX1668
./scripts/config --disable SENSORS_MAX197
./scripts/config --disable SENSORS_MAX31722
./scripts/config --disable SENSORS_MAX6621
./scripts/config --disable SENSORS_MAX6639
./scripts/config --disable SENSORS_MAX6642
./scripts/config --disable SENSORS_MAX6650
./scripts/config --disable SENSORS_MAX6697
./scripts/config --disable SENSORS_MCP3021
./scripts/config --disable SENSORS_NCT6683
./scripts/config --disable SENSORS_NCT7802
./scripts/config --disable SENSORS_NCT7904
./scripts/config --disable SENSORS_NTC_THERMISTOR
./scripts/config --disable SENSORS_PC87360
./scripts/config --disable SENSORS_PC87427
./scripts/config --disable SENSORS_PCF8591
./scripts/config --disable SENSORS_PWM_FAN
./scripts/config --disable SENSORS_SHT15
./scripts/config --disable SENSORS_SHT21
./scripts/config --disable SENSORS_SIS5595
./scripts/config --disable SENSORS_SMSC47B397
./scripts/config --disable SENSORS_SMSC47M1
./scripts/config --disable SENSORS_SMSC47M192
./scripts/config --disable SENSORS_STTS751
./scripts/config --disable SENSORS_TMP102
./scripts/config --disable SENSORS_TMP103
./scripts/config --disable SENSORS_TMP108
./scripts/config --disable SENSORS_TMP401
./scripts/config --disable SENSORS_TMP421
./scripts/config --disable SENSORS_VIA686A
./scripts/config --disable SENSORS_VT1211
./scripts/config --disable SENSORS_VT8231
./scripts/config --disable SENSORS_W83627EHF
./scripts/config --disable SENSORS_W83627HF
./scripts/config --disable SENSORS_W83773G
./scripts/config --disable SENSORS_W83781D
./scripts/config --disable SENSORS_W83791D
./scripts/config --disable SENSORS_W83792D
./scripts/config --disable SENSORS_W83793
./scripts/config --disable SENSORS_W83795
./scripts/config --disable SENSORS_W83L785TS
./scripts/config --disable SENSORS_W83L786NG

#######################################
# DISABLE MFD (Multi-Function Device)
#######################################
echo "[*] Disabling embedded MFD drivers..."
./scripts/config --disable MFD_ACT8945A
./scripts/config --disable MFD_AS3711
./scripts/config --disable MFD_AS3722
./scripts/config --disable MFD_ATMEL_FLEXCOM
./scripts/config --disable MFD_ATMEL_HLCDC
./scripts/config --disable MFD_AXP20X
./scripts/config --disable MFD_BD9571MWV
./scripts/config --disable MFD_CROS_EC
./scripts/config --disable MFD_DA9052_I2C
./scripts/config --disable MFD_DA9055
./scripts/config --disable MFD_DA9062
./scripts/config --disable MFD_DA9063
./scripts/config --disable MFD_DA9150
./scripts/config --disable MFD_DLN2
./scripts/config --disable MFD_HI6421_PMIC
./scripts/config --disable MFD_HI6421_SPMI
./scripts/config --disable MFD_HI655X_PMIC
./scripts/config --disable MFD_LP3943
./scripts/config --disable MFD_LP873X
./scripts/config --disable MFD_LP87565
./scripts/config --disable MFD_MAX14577
./scripts/config --disable MFD_MAX77620
./scripts/config --disable MFD_MAX77650
./scripts/config --disable MFD_MAX77686
./scripts/config --disable MFD_MAX77693
./scripts/config --disable MFD_MAX77843
./scripts/config --disable MFD_MAX8907
./scripts/config --disable MFD_MAX8925
./scripts/config --disable MFD_MAX8997
./scripts/config --disable MFD_MAX8998
./scripts/config --disable MFD_MT6360
./scripts/config --disable MFD_MT6397
./scripts/config --disable MFD_PALMAS
./scripts/config --disable MFD_RETU
./scripts/config --disable MFD_RK808
./scripts/config --disable MFD_RN5T618
./scripts/config --disable MFD_RT5033
./scripts/config --disable MFD_SEC_CORE
./scripts/config --disable MFD_STMPE
# MFD_SYSCON - keep enabled, sometimes needed on x86
# ./scripts/config --disable MFD_SYSCON
./scripts/config --disable MFD_TC3589X
./scripts/config --disable MFD_TI_AM335X_TSCADC
./scripts/config --disable MFD_TI_LP87565
./scripts/config --disable MFD_TI_LMU
./scripts/config --disable MFD_TPS65090
./scripts/config --disable MFD_TPS65217
./scripts/config --disable MFD_TI_LP873X
./scripts/config --disable MFD_TPS65218
./scripts/config --disable MFD_TPS6586X
./scripts/config --disable MFD_TPS65910
./scripts/config --disable MFD_TPS65912_I2C
./scripts/config --disable MFD_TPS65912_SPI
./scripts/config --disable MFD_TPS80031
./scripts/config --disable MFD_TWLCORE
./scripts/config --disable MFD_WM8994
./scripts/config --disable MFD_WCD934X
./scripts/config --disable MFD_ATC260X

#######################################
# DISABLE LED DRIVERS
#######################################
echo "[*] Disabling embedded LED drivers..."
./scripts/config --disable NEW_LEDS
./scripts/config --disable LEDS_CLASS
./scripts/config --disable LEDS_TRIGGERS

#######################################
# SPECIALIZED HARDWARE
#######################################
echo "[*] Disabling specialized hardware subsystems..."
./scripts/config --disable FPGA
./scripts/config --disable GNSS
./scripts/config --disable GREYBUS
./scripts/config --disable SIOX
./scripts/config --disable SLIMBUS
./scripts/config --disable MOST
./scripts/config --disable IIO
./scripts/config --disable AUXDISPLAY
./scripts/config --disable ACCESSIBILITY

#######################################
# DISABLE MEMORY HOTPLUG (laptop, not server)
#######################################
echo "[*] Disabling memory hotplug..."
./scripts/config --disable MEMORY_HOTPLUG
./scripts/config --disable MEMORY_HOTREMOVE

#######################################
# DISABLE UNUSED SCSI CONTROLLERS
#######################################
echo "[*] Disabling unused SCSI controllers..."
./scripts/config --disable MEGARAID_NEWGEN
./scripts/config --disable MEGARAID_SAS
./scripts/config --disable FUSION
./scripts/config --disable SCSI_AACRAID
./scripts/config --disable SCSI_AIC7XXX
./scripts/config --disable SCSI_AIC79XX
./scripts/config --disable SCSI_MVSAS
./scripts/config --disable SCSI_MVUMI
./scripts/config --disable SCSI_MPT3SAS
./scripts/config --disable SCSI_SYM53C8XX_2
./scripts/config --disable SCSI_IPR
./scripts/config --disable SCSI_QLA_FC
./scripts/config --disable SCSI_QLA_ISCSI
./scripts/config --disable SCSI_BNX2_ISCSI
./scripts/config --disable SCSI_CXGB3_ISCSI
./scripts/config --disable SCSI_CXGB4_ISCSI
./scripts/config --disable SCSI_SMARTPQI
./scripts/config --disable SCSI_HPSA
./scripts/config --disable SCSI_UFSHCD

#######################################
# DISABLE UNUSED FILESYSTEMS
#######################################
echo "[*] Disabling unused filesystems..."
./scripts/config --disable XFS_FS
./scripts/config --disable BTRFS_FS
./scripts/config --disable ECRYPT_FS
./scripts/config --disable CIFS
./scripts/config --disable CIFS_DEBUG
./scripts/config --disable 9P_FS
./scripts/config --disable AFS_FS
./scripts/config --disable CEPH_FS
./scripts/config --disable ORANGEFS_FS
./scripts/config --disable GFS2_FS
./scripts/config --disable OCFS2_FS
./scripts/config --disable NILFS2_FS
./scripts/config --disable REISERFS_FS
./scripts/config --disable JFS_FS
./scripts/config --disable HFS_FS
./scripts/config --disable HFSPLUS_FS
./scripts/config --disable MINIX_FS
./scripts/config --disable ROMFS_FS
./scripts/config --disable CRAMFS
./scripts/config --disable SQUASHFS

#######################################
# DISABLE UNUSED VHOST/VFIO (VM passthrough)
#######################################
echo "[*] Disabling VM passthrough (VHOST/VFIO)..."
./scripts/config --disable VHOST_MENU
./scripts/config --disable VHOST_NET
./scripts/config --disable VHOST_SCSI
./scripts/config --disable VHOST_VSOCK
./scripts/config --disable VFIO

#######################################
# DISABLE SOUNDWIRE (not used on this system)
#######################################
echo "[*] Disabling SoundWire..."
./scripts/config --disable SOUNDWIRE

#######################################
# DISABLE BOOT LOGO (saves a tiny bit)
#######################################
echo "[*] Disabling boot logo..."
./scripts/config --disable LOGO
./scripts/config --disable FB_BOOT_VESA_SUPPORT

#######################################
# DISABLE NFS (not used)
#######################################
echo "[*] Disabling NFS..."
./scripts/config --disable NFS_FS
./scripts/config --disable NFSD
./scripts/config --disable NFS_V4

#######################################
# DISABLE MACINTOSH/LEGACY DRIVERS
#######################################
echo "[*] Disabling Macintosh/legacy drivers..."
./scripts/config --disable MACINTOSH_DRIVERS
./scripts/config --disable MAC_EMUMOUSEBTN
./scripts/config --disable MAC_PARTITION
./scripts/config --disable PATA_SIS

#######################################
# DISABLE PCI HOTPLUG (laptop, not server)
#######################################
echo "[*] Disabling PCI hotplug..."
./scripts/config --disable HOTPLUG_PCI
./scripts/config --disable HOTPLUG_PCI_CPCI
./scripts/config --disable HOTPLUG_PCI_SHPC

#######################################
# DISABLE EDAC/ECC (no ECC RAM on laptop)
#######################################
echo "[*] Disabling EDAC/ECC memory checking..."
./scripts/config --disable EDAC

#######################################
# DISABLE STAGING DRIVERS
#######################################
echo "[*] Disabling staging drivers..."
./scripts/config --disable STAGING
./scripts/config --disable STAGING_MEDIA

#######################################
# DISABLE NON-DELL PLATFORM DRIVERS
#######################################
echo "[*] Disabling non-Dell platform drivers..."
./scripts/config --disable CHROME_PLATFORMS
./scripts/config --disable SURFACE_PLATFORMS
./scripts/config --disable X86_PLATFORM_DRIVERS_HP

#######################################
# DISABLE IR REMOTE CONTROL
#######################################
echo "[*] Disabling IR remote control..."
./scripts/config --disable RC_CORE
./scripts/config --disable LIRC
./scripts/config --disable MEDIA_RC_SUPPORT

#######################################
# DISABLE LEGACY WIRELESS EXTENSIONS
#######################################
echo "[*] Disabling legacy wireless extensions..."
./scripts/config --disable CFG80211_WEXT

#######################################
# DISABLE SAMSUNG BATTERY (not your laptop)
#######################################
echo "[*] Disabling Samsung battery driver..."
./scripts/config --disable BATTERY_SAMSUNG_SDI

#######################################
# DISABLE DISK QUOTAS (not used)
#######################################
echo "[*] Disabling disk quotas..."
./scripts/config --disable QUOTA

#######################################
# DISABLE HIBERNATION (not used)
#######################################
echo "[*] Disabling hibernation..."
./scripts/config --disable HIBERNATION

#######################################
# DISABLE PC SPEAKER
#######################################
echo "[*] Disabling PC speaker..."
./scripts/config --disable PCSPKR_PLATFORM
./scripts/config --disable INPUT_PCSPKR
./scripts/config --disable SND_PCSP

#######################################
# DISABLE MPLS (carrier-grade networking)
#######################################
echo "[*] Disabling MPLS..."
./scripts/config --disable MPLS

#######################################
# DISABLE NETWORK SWITCH/L3 MASTER (not a router)
#######################################
echo "[*] Disabling network switch support..."
./scripts/config --disable NET_SWITCHDEV
./scripts/config --disable NET_L3_MASTER_DEV

#######################################
# DISABLE LEGACY SYSCALLS
#######################################
echo "[*] Disabling legacy syscalls..."
./scripts/config --disable SYSFS_SYSCALL
./scripts/config --disable UID16

#######################################
# DISABLE PROC DEBUG FEATURES
#######################################
echo "[*] Disabling proc debug features..."
./scripts/config --disable PROC_KCORE

#######################################
# DISABLE PROCESS ACCOUNTING (not needed for Docker/DisplayLink)
#######################################
echo "[*] Disabling process accounting..."
# BSD process accounting - logs process info at exit, not needed
./scripts/config --disable BSD_PROCESS_ACCT
./scripts/config --disable BSD_PROCESS_ACCT_V3
# Task statistics - only needed for advanced monitoring (iotop), Docker works without
./scripts/config --disable TASKSTATS
./scripts/config --disable TASK_DELAY_ACCT
./scripts/config --disable TASK_XACCT
./scripts/config --disable TASK_IO_ACCOUNTING
# ACPI debug - production system doesn't need ACPI debugging
./scripts/config --disable ACPI_DEBUG
# DMI sysfs - rarely used, exposes hardware info via sysfs
./scripts/config --disable DMI_SYSFS

#######################################
# DISABLE UNUSED CRYPTO MODULES
#######################################
echo "[*] Disabling unused crypto modules..."
./scripts/config --disable CRYPTO_ECRDSA
./scripts/config --disable CRYPTO_ECDSA
./scripts/config --disable CRYPTO_SM2
./scripts/config --disable CRYPTO_CURVE25519

#######################################
# PERFORMANCE OPTIMIZATIONS
#######################################
echo "[*] Enabling performance optimizations..."

# Compiler optimization is set in the LTO section above (-O2)

# Timer frequency - 1000Hz for responsive desktop
# Higher tick rate = better latency, slightly more overhead
# 1000Hz is ideal for interactive desktop use
./scripts/config --enable HZ_1000
./scripts/config --set-val HZ 1000

# Preemption - voluntary for balanced throughput/latency
# Use PREEMPT_NONE for pure throughput (servers)
# Use PREEMPT for lowest latency (real-time)
./scripts/config --enable PREEMPT_VOLUNTARY
./scripts/config --disable PREEMPT_NONE
./scripts/config --disable PREEMPT

# Transparent hugepages for better memory performance
./scripts/config --enable TRANSPARENT_HUGEPAGE
./scripts/config --enable TRANSPARENT_HUGEPAGE_ALWAYS

# CPU idle optimizations
./scripts/config --enable CPU_IDLE
./scripts/config --enable CPU_FREQ
./scripts/config --enable CPU_FREQ_GOV_PERFORMANCE

# Disable kernel live patching (not needed, adds overhead)
./scripts/config --disable LIVEPATCH

# Disable NUMA for single-socket systems (your laptop)
./scripts/config --disable NUMA

# TCP BBR congestion control (better throughput than CUBIC)
./scripts/config --enable TCP_CONG_BBR
./scripts/config --set-str DEFAULT_TCP_CONG bbr

# Disable cgroup v1 (legacy, slight overhead if not used)
./scripts/config --disable MEMCG_V1
./scripts/config --disable CPUSETS_V1

# Enable full tickless (idle + active) for better power/perf
./scripts/config --enable NO_HZ_FULL

# Disable memory balloon (VM feature, not needed bare metal)
./scripts/config --disable MEMORY_BALLOON
./scripts/config --disable BALLOON_COMPACTION

# Disable watchdog (not needed on desktop)
./scripts/config --disable WATCHDOG

# Disable kernel crash dump (saves memory)
./scripts/config --disable CRASH_DUMP
./scripts/config --disable KEXEC_CORE
./scripts/config --disable KEXEC
# Also disable kexec file-based loading and signature verification
./scripts/config --disable KEXEC_FILE
./scripts/config --disable KEXEC_SIG

# Disable unused filesystem debug
./scripts/config --disable EXT4_DEBUG
./scripts/config --disable XFS_DEBUG
./scripts/config --disable BTRFS_DEBUG
./scripts/config --disable F2FS_CHECK_FS

# Disable BPF JIT hardening (for max BPF performance)
./scripts/config --disable BPF_JIT_HARDENING

# Disable userfaultfd (rarely used, attack surface)
./scripts/config --disable USERFAULTFD

# Optimize for size where it doesn't hurt (network stack)
./scripts/config --disable NET_DROP_MONITOR
./scripts/config --disable NET_FLOW_LIMIT

#######################################
# OPTIONAL: LOCALMODCONFIG (reduces build time ~70%)
#######################################
# Uncomment the following to only build modules currently loaded
# WARNING: May miss modules for devices not currently in use!
#
# echo "[*] Running localmodconfig to strip unused modules..."
# lsmod > /tmp/lsmod.now
# make LLVM=$LLVM_VERSION LSMOD=/tmp/lsmod.now localmodconfig

#######################################
# REGENERATE CONFIG & BUILD
#######################################
echo ""
echo "[*] Regenerating config with olddefconfig..."
make LLVM=$LLVM_VERSION olddefconfig

echo ""
echo "=== Configuration complete ==="
echo ""
echo "Review changes with: diff .config.backup.* .config | head -100"
echo ""
read -p "Proceed with build? [y/N] " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Build skipped. Run manually with:"
    echo "  make LLVM=$LLVM_VERSION -j$JOBS"
    echo ""
    exit 0
fi

KERNEL_DIR="$(pwd)"
EVDI_DIR="/tmp/evdi"
KERNEL_VERSION=$(make LLVM=$LLVM_VERSION kernelrelease 2>/dev/null || echo "unknown")

echo ""
echo "[*] Building kernel with LLVM$LLVM_VERSION and $JOBS jobs..."
echo "[*] This will take a while (LTO linking is slow)..."
echo ""

time make LLVM=$LLVM_VERSION -j$JOBS

echo ""
echo "=== Kernel build complete ==="
echo ""

#######################################
# INSTALL KERNEL MODULES
#######################################
echo "[*] Installing kernel modules..."
sudo make LLVM=$LLVM_VERSION modules_install

#######################################
# CLONE EVDI FROM OFFICIAL REPOSITORY
#######################################
echo ""
echo "[*] Cloning evdi driver from official repository..."

# Remove existing evdi directory if present (ensures clean build)
if [ -d "$EVDI_DIR" ]; then
    echo "[*] Removing existing $EVDI_DIR..."
    rm -rf "$EVDI_DIR"
fi

# Clone with shallow depth for speed (only need latest commit)
if ! git clone --depth 1 https://github.com/DisplayLink/evdi.git "$EVDI_DIR"; then
    echo "[!] ERROR: Failed to clone evdi repository"
    echo "[!] Check your internet connection and try again"
    exit 1
fi

#######################################
# BUILD EVDI MODULE
#######################################
echo ""
echo "[*] Building evdi module against new kernel..."
cd "$EVDI_DIR/module"
make clean
# Must use same LLVM toolchain as kernel to avoid compiler mismatch
make KDIR="$KERNEL_DIR" LLVM=$LLVM_VERSION CC=clang$LLVM_VERSION -j$JOBS

if [ $? -ne 0 ]; then
    echo "[!] ERROR: Failed to build evdi module"
    exit 1
fi

echo ""
echo "[*] Installing evdi module..."
sudo make KDIR="$KERNEL_DIR" LLVM=$LLVM_VERSION install

if [ $? -ne 0 ]; then
    echo "[!] ERROR: Failed to install evdi module"
    exit 1
fi

# Return to kernel directory
cd "$KERNEL_DIR"

# Clean up /tmp/evdi after successful build (optional, saves ~50MB)
echo "[*] Cleaning up $EVDI_DIR..."
rm -rf "$EVDI_DIR"

#######################################
# INSTALL KERNEL (manual to avoid DKMS hooks)
#######################################
echo ""
echo "[*] Installing kernel (bypassing DKMS hooks)..."
cd "$KERNEL_DIR"

# Copy kernel files manually to avoid triggering DKMS post-install hooks
sudo cp arch/x86/boot/bzImage /boot/vmlinuz-$KERNEL_VERSION
sudo cp System.map /boot/System.map-$KERNEL_VERSION
sudo cp .config /boot/config-$KERNEL_VERSION

# Generate initramfs
echo "[*] Generating initramfs..."
sudo update-initramfs -c -k $KERNEL_VERSION

# Update bootloader
echo "[*] Updating GRUB..."
sudo update-grub

echo ""
echo "=== Installation complete ==="
echo "Kernel version: $KERNEL_VERSION"
echo ""

#######################################
# REBOOT
#######################################
read -p "Reboot now? [y/N] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "[*] Rebooting..."
    sudo reboot
else
    echo ""
    echo "Reboot skipped. Reboot manually when ready."
    echo ""
    echo "=== RECOMMENDED BOOT PARAMETERS ==="
    echo "Add these to GRUB_CMDLINE_LINUX_DEFAULT in /etc/default/grub:"
    echo ""
    echo '  mitigations=off nowatchdog processor.ignore_ppc=1 split_lock_detect=off'
    echo ""
    echo "Then run: sudo update-grub && sudo reboot"
    echo ""
fi
