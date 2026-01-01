#!/bin/bash
# ============================================================================
# KERNEL CONFIGURATION SCRIPT
# ============================================================================
# Shared configuration for bespoke kernel build.
# Can be run standalone or sourced by build.sh and trace_build.sh.
#
# Target: Dell Laptop with Intel Kaby Lake i7-7500U
# Kernel: Linux 6.18
# Toolchain: LLVM/Clang 19 with ThinLTO
#
# Usage:
#   ./scripts/bespoke/config.sh          # Run standalone
#   source scripts/bespoke/config.sh     # Source from another script
#
# ============================================================================

# Detect kernel directory
if [[ -z "${KERNEL_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    KERNEL_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi

cd "$KERNEL_DIR" || exit 1

# Verify we're in kernel source
if [[ ! -f "Makefile" ]] || ! grep -q "VERSION = 6" Makefile; then
    echo "[ERROR] Must run from kernel source root" >&2
    exit 1
fi

# LLVM toolchain version
LLVM_VERSION="-19"

# Ensure we have a base config to modify
if [[ ! -f ".config" ]]; then
    echo "[*] No .config found, generating defconfig..."
    make LLVM=$LLVM_VERSION defconfig
fi

# Backup current config
cp .config ".config.backup.$(date +%Y%m%d_%H%M%S)"
echo "[+] Backed up current .config"

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
echo "[*] Using -O2 optimization (kernel default, best stability)..."
./scripts/config --enable CC_OPTIMIZE_FOR_PERFORMANCE
./scripts/config --disable CC_OPTIMIZE_FOR_SIZE

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

# Disable core dump support
./scripts/config --disable COREDUMP
./scripts/config --disable ELF_CORE
./scripts/config --disable DEV_COREDUMP

# Disable Magic SysRq
./scripts/config --disable MAGIC_SYSRQ

# Disable relay filesystem
./scripts/config --disable RELAY

# Disable kernel symbol table
./scripts/config --disable KALLSYMS

# Disable boot-time memory testing
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

# Disable memory protection
./scripts/config --disable RANDOMIZE_KSTACK_OFFSET_DEFAULT

# Zero registers on function return
./scripts/config --disable ZERO_CALL_USED_REGS

#######################################
# DISABLE VIRTUALIZATION GUEST OVERHEAD
#######################################
echo "[*] Disabling virtualization guest support (bare metal)..."

# Hypervisor guest support
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

# Disable KVM
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

#######################################
# DISABLE MODULE SIGNING
#######################################
echo "[*] Disabling module signing..."
./scripts/config --disable MODULE_SIG
./scripts/config --disable MODULE_SIG_ALL
./scripts/config --disable MODVERSIONS
./scripts/config --disable MODULE_SRCVERSION_ALL

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
# DISPLAYLINK / USB DISPLAY CONFIGURATION
#######################################
echo "[*] Configuring DisplayLink support..."

# DRM_SIMPLEDRM for FB_SYS_* symbols required by evdi
./scripts/config --module DRM_SIMPLEDRM

# Legacy DisplayLink drivers - safe to disable (replaced by EVDI)
./scripts/config --disable FB_UDLFB
./scripts/config --disable USB_UDL
./scripts/config --disable DRM_UDL

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

#######################################
# DISABLE SPECIALIZED HARDWARE
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
# DISABLE MEMORY HOTPLUG
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
# DISABLE UNUSED VHOST/VFIO
#######################################
echo "[*] Disabling VM passthrough (VHOST/VFIO)..."
./scripts/config --disable VHOST_MENU
./scripts/config --disable VHOST_NET
./scripts/config --disable VHOST_SCSI
./scripts/config --disable VHOST_VSOCK
./scripts/config --disable VFIO

#######################################
# DISABLE SOUNDWIRE
#######################################
echo "[*] Disabling SoundWire..."
./scripts/config --disable SOUNDWIRE

#######################################
# DISABLE BOOT LOGO
#######################################
echo "[*] Disabling boot logo..."
./scripts/config --disable LOGO
./scripts/config --disable FB_BOOT_VESA_SUPPORT

#######################################
# DISABLE NFS
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
# DISABLE PCI HOTPLUG
#######################################
echo "[*] Disabling PCI hotplug..."
./scripts/config --disable HOTPLUG_PCI
./scripts/config --disable HOTPLUG_PCI_CPCI
./scripts/config --disable HOTPLUG_PCI_SHPC

#######################################
# DISABLE EDAC/ECC
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
# DISABLE SAMSUNG BATTERY
#######################################
echo "[*] Disabling Samsung battery driver..."
./scripts/config --disable BATTERY_SAMSUNG_SDI

#######################################
# DISABLE DISK QUOTAS
#######################################
echo "[*] Disabling disk quotas..."
./scripts/config --disable QUOTA

#######################################
# DISABLE HIBERNATION
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
# DISABLE MPLS
#######################################
echo "[*] Disabling MPLS..."
./scripts/config --disable MPLS

#######################################
# DISABLE NETWORK SWITCH/L3 MASTER
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
# DISABLE PROCESS ACCOUNTING
#######################################
echo "[*] Disabling process accounting..."
./scripts/config --disable BSD_PROCESS_ACCT
./scripts/config --disable BSD_PROCESS_ACCT_V3
./scripts/config --disable TASKSTATS
./scripts/config --disable TASK_DELAY_ACCT
./scripts/config --disable TASK_XACCT
./scripts/config --disable TASK_IO_ACCOUNTING
./scripts/config --disable ACPI_DEBUG
./scripts/config --disable DMI_SYSFS

#######################################
# PERFORMANCE OPTIMIZATIONS
#######################################
echo "[*] Enabling performance optimizations..."

# Timer frequency - 1000Hz for responsive desktop
./scripts/config --enable HZ_1000
./scripts/config --set-val HZ 1000

# Preemption - voluntary for balanced throughput/latency
./scripts/config --enable PREEMPT_VOLUNTARY
./scripts/config --disable PREEMPT_NONE
./scripts/config --disable PREEMPT

# Transparent hugepages
./scripts/config --enable TRANSPARENT_HUGEPAGE
./scripts/config --enable TRANSPARENT_HUGEPAGE_ALWAYS

# CPU idle optimizations
./scripts/config --enable CPU_IDLE
./scripts/config --enable CPU_FREQ
./scripts/config --enable CPU_FREQ_GOV_PERFORMANCE

# Disable kernel live patching
./scripts/config --disable LIVEPATCH

# Disable NUMA for single-socket
./scripts/config --disable NUMA

# TCP BBR congestion control
./scripts/config --enable TCP_CONG_BBR
./scripts/config --set-str DEFAULT_TCP_CONG bbr

# Disable cgroup v1
./scripts/config --disable MEMCG_V1
./scripts/config --disable CPUSETS_V1

# Enable full tickless
./scripts/config --enable NO_HZ_FULL

# Disable memory balloon
./scripts/config --disable MEMORY_BALLOON
./scripts/config --disable BALLOON_COMPACTION

# Disable watchdog
./scripts/config --disable WATCHDOG

# Disable kernel crash dump
./scripts/config --disable CRASH_DUMP
./scripts/config --disable KEXEC_CORE
./scripts/config --disable KEXEC
./scripts/config --disable KEXEC_FILE
./scripts/config --disable KEXEC_SIG

# Disable unused filesystem debug
./scripts/config --disable EXT4_DEBUG
./scripts/config --disable XFS_DEBUG
./scripts/config --disable BTRFS_DEBUG
./scripts/config --disable F2FS_CHECK_FS

# Disable BPF JIT hardening
./scripts/config --disable BPF_JIT_HARDENING

# Disable userfaultfd
./scripts/config --disable USERFAULTFD

# Optimize network stack
./scripts/config --disable NET_DROP_MONITOR
./scripts/config --disable NET_FLOW_LIMIT

#######################################
# REGENERATE CONFIG
#######################################
echo ""
echo "[*] Regenerating config with olddefconfig..."
make LLVM=$LLVM_VERSION olddefconfig

echo ""
echo "=== Configuration complete ==="
