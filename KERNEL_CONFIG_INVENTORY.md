# Kernel Configuration Inventory - Disabled Options

This document catalogs all kernel configuration options being disabled in `build.sh` for the Dell laptop optimized kernel build.

**Total Active `./scripts/config --disable` Commands: 322**

*(3 additional commands are commented out: RANDOMIZE_BASE, RANDOMIZE_MEMORY, CC_OPTIMIZE_FOR_PERFORMANCE)*

---

## Category Summary

| # | Category | Count | Lines in build.sh |
|---|----------|-------|-------------------|
| 1 | LTO Control | 1 | 30 |
| 2 | CPU Vulnerability Mitigations | 18 | 44-61 |
| 3 | Debug Options | 5 | 67-72 |
| 4 | Tracing/Profiling | 6 | 75-80 |
| 5 | Kernel Sanitizers | 3 | 83-85 |
| 6 | Security - Stack Protection | 2 | 93-94 |
| 7 | Security - Memory Hardening | 9 | 97-115 |
| 8 | Virtualization Guest Support | 14 | 123-138 |
| 9 | Audit Subsystem | 2 | 144-145 |
| 10 | Security Frameworks | 4 | 151-154 |
| 11 | Module Signing | 4 | 160-163 |
| 12 | Power Management Debug | 6 | 169-174 |
| 13 | Scheduler Debug/Stats | 4 | 180-183 |
| 14 | Printk Overhead | 3 | 189-191 |
| 15 | GPU - i915 Debug | 2 | 197-198 |
| 16 | GPU - DisplayLink/USB (ISSUE!) | 4 | 204-207 |
| 17 | GPU - Unused Drivers | 10 | 213-222 |
| 18 | WiFi - Unused Vendors | 17 | 228-244 |
| 19 | Ethernet - Unused Vendors | 70 | 250-319 |
| 20 | Obsolete Network Subsystems | 15 | 325-339 |
| 21 | Input Devices | 4 | 345-348 |
| 22 | Legacy Ports | 3 | 354-356 |
| 23 | Media/DVB Drivers | 6 | 362-367 |
| 24 | Specialized Hardware | 9 | 373-381 |
| 25 | Memory Hotplug | 2 | 387-388 |
| 26 | SCSI Controllers | 19 | 394-412 |
| 27 | Filesystems | 18 | 418-435 |
| 28 | VM Passthrough (VHOST/VFIO) | 5 | 441-445 |
| 29 | SoundWire | 1 | 451 |
| 30 | Boot Logo | 2 | 457-458 |
| 31 | NFS | 3 | 464-466 |
| 32 | Macintosh/Legacy Drivers | 4 | 472-475 |
| 33 | PCI Hotplug | 3 | 481-483 |
| 34 | EDAC/ECC | 1 | 489 |
| 35 | Staging Drivers | 2 | 495-496 |
| 36 | Non-Dell Platform Drivers | 3 | 502-504 |
| 37 | IR Remote Control | 3 | 510-512 |
| 38 | Legacy Wireless Extensions | 1 | 518 |
| 39 | Samsung Battery | 1 | 524 |
| 40 | Disk Quotas | 1 | 530 |
| 41 | Hibernation | 1 | 536 |
| 42 | PC Speaker | 3 | 542-544 |
| 43 | MPLS | 1 | 550 |
| 44 | Network Switch/L3 | 2 | 556-557 |
| 45 | Legacy Syscalls | 2 | 563-564 |
| 46 | Proc Debug | 1 | 570 |
| 47 | Performance Tuning (disables) | 19 | 579-643 |
| **TOTAL** | | **322** | |

---

## Detailed Listing by Category

### 1. LTO Control (Line 30)
```
LTO_NONE
```
**Count: 1**

---

### 2. CPU Vulnerability Mitigations (Lines 44-61)
```
MITIGATION_PAGE_TABLE_ISOLATION
MITIGATION_RETPOLINE
MITIGATION_IBPB_ENTRY
MITIGATION_IBRS_ENTRY
MITIGATION_SLS
MITIGATION_GDS
MITIGATION_RFDS
MITIGATION_SPECTRE_BHI
MITIGATION_MDS
MITIGATION_TAA
MITIGATION_MMIO_STALE_DATA
MITIGATION_L1TF
MITIGATION_SPECTRE_V1
MITIGATION_SPECTRE_V2
MITIGATION_SRBDS
MITIGATION_SSB
MITIGATION_TSA
MITIGATION_VMSCAPE
```
**Count: 18**

---

### 3. Debug Options (Lines 67-72)
```
DEBUG_KERNEL
DEBUG_INFO
DEBUG_BUGVERBOSE
SCHED_DEBUG
DEBUG_PREEMPT
```
**Count: 5**

---

### 4. Tracing/Profiling (Lines 75-80)
```
FTRACE
FUNCTION_TRACER
STACK_TRACER
TRACING
KPROBES
PROFILING
```
**Count: 6**

---

### 5. Kernel Sanitizers (Lines 83-85)
```
KASAN
UBSAN
KCSAN
```
**Count: 3**

---

### 6. Security - Stack Protection (Lines 93-94)
```
STACKPROTECTOR
STACKPROTECTOR_STRONG
```
**Count: 2**

---

### 7. Security - Memory Hardening (Lines 97-115)
```
FORTIFY_SOURCE
HARDENED_USERCOPY
SLAB_FREELIST_RANDOM
SLAB_FREELIST_HARDENED
INIT_ON_ALLOC_DEFAULT_ON
INIT_ON_FREE_DEFAULT_ON
PAGE_POISONING
INIT_STACK_ALL_ZERO
RANDOMIZE_KSTACK_OFFSET_DEFAULT
ZERO_CALL_USED_REGS
```
**Count: 10** *(INIT_STACK_NONE is enabled, not disabled)*
**Active Disables: 9** *(RANDOMIZE_BASE and RANDOMIZE_MEMORY are commented out)*

---

### 8. Virtualization Guest Support (Lines 123-138)
```
HYPERVISOR_GUEST
PARAVIRT
PARAVIRT_XXL
PARAVIRT_SPINLOCKS
KVM_GUEST
XEN
XEN_PV
XEN_PVHVM
XEN_512GB
XEN_PVH
VIRTUALIZATION
KVM
KVM_INTEL
KVM_AMD
```
**Count: 14**

---

### 9. Audit Subsystem (Lines 144-145)
```
AUDIT
AUDITSYSCALL
```
**Count: 2**

---

### 10. Security Frameworks (Lines 151-154)
```
SECURITY_SELINUX
SECURITY_APPARMOR
SECCOMP
SECCOMP_FILTER
```
**Count: 4**

**WARNING: Docker uses SECCOMP - may need `--security-opt seccomp=unconfined`**

---

### 11. Module Signing (Lines 160-163)
```
MODULE_SIG
MODULE_SIG_ALL
MODVERSIONS
MODULE_SRCVERSION_ALL
```
**Count: 4**

---

### 12. Power Management Debug (Lines 169-174)
```
PM_DEBUG
PM_ADVANCED_DEBUG
PM_SLEEP_DEBUG
PM_TRACE
PM_TRACE_RTC
ACPI_DEBUGGER
```
**Count: 6**

---

### 13. Scheduler Debug/Stats (Lines 180-183)
```
SCHED_STACK_END_CHECK
SCHED_INFO
SCHEDSTATS
LATENCYTOP
```
**Count: 4**

---

### 14. Printk Overhead (Lines 189-191)
```
PRINTK_TIME
PRINTK_CALLER
SYMBOLIC_ERRNAME
```
**Count: 3**

---

### 15. GPU - i915 Debug (Lines 197-198)
```
DRM_I915_CAPTURE_ERROR
DRM_I915_COMPRESS_ERROR
```
**Count: 2**

---

### 16. GPU - DisplayLink/USB Display (Lines 204-207)
**CRITICAL ISSUE: These disable DisplayLink support!**
```
DRM_EVDI
FB_UDLFB
USB_UDL
DRM_UDL
```
**Count: 4**

**STATUS: INCORRECTLY DISABLED - DisplayLink requires EVDI!**
The section header says "DISABLE DISPLAYLINK" but the stated goal is to support DisplayLink.

---

### 17. GPU - Unused Drivers (Lines 213-222)
```
DRM_NOUVEAU
DRM_AMDGPU
DRM_RADEON
DRM_VMWGFX
DRM_QXL
DRM_VIRTIO_GPU
DRM_BOCHS
DRM_CIRRUS_QEMU
DRM_AST
DRM_MGAG200
```
**Count: 10**

---

### 18. WiFi - Unused Vendors (Lines 228-244)
```
WLAN_VENDOR_ADMTEK
WLAN_VENDOR_ATMEL
WLAN_VENDOR_BROADCOM
WLAN_VENDOR_INTEL
WLAN_VENDOR_INTERSIL
WLAN_VENDOR_MARVELL
WLAN_VENDOR_MEDIATEK
WLAN_VENDOR_MICROCHIP
WLAN_VENDOR_PURELIFI
WLAN_VENDOR_RALINK
WLAN_VENDOR_REALTEK
WLAN_VENDOR_RSI
WLAN_VENDOR_SILABS
WLAN_VENDOR_ST
WLAN_VENDOR_TI
WLAN_VENDOR_ZYDAS
WLAN_VENDOR_QUANTENNA
```
**Count: 17**

*Note: WLAN_VENDOR_ATHEROS is correctly NOT disabled (required for QCA6174)*

---

### 19. Ethernet - Unused Vendors (Lines 250-319)
```
NET_VENDOR_3COM
NET_VENDOR_ADAPTEC
NET_VENDOR_AGERE
NET_VENDOR_ALACRITECH
NET_VENDOR_ALTEON
NET_VENDOR_AMAZON
NET_VENDOR_AMD
NET_VENDOR_AQUANTIA
NET_VENDOR_ARC
NET_VENDOR_ASIX
NET_VENDOR_ATHEROS
NET_VENDOR_BROADCOM
NET_VENDOR_CADENCE
NET_VENDOR_CAVIUM
NET_VENDOR_CHELSIO
NET_VENDOR_CISCO
NET_VENDOR_CORTINA
NET_VENDOR_DAVICOM
NET_VENDOR_DEC
NET_VENDOR_DLINK
NET_VENDOR_EMULEX
NET_VENDOR_ENGLEDER
NET_VENDOR_EZCHIP
NET_VENDOR_FUNGIBLE
NET_VENDOR_GOOGLE
NET_VENDOR_HUAWEI
NET_VENDOR_INTEL
NET_VENDOR_LITEX
NET_VENDOR_MARVELL
NET_VENDOR_MELLANOX
NET_VENDOR_MICREL
NET_VENDOR_MICROCHIP
NET_VENDOR_MICROSEMI
NET_VENDOR_MICROSOFT
NET_VENDOR_MYRI
NET_VENDOR_NATSEMI
NET_VENDOR_NETERION
NET_VENDOR_NETRONOME
NET_VENDOR_NI
NET_VENDOR_NVIDIA
NET_VENDOR_OKI
NET_VENDOR_PACKET_ENGINES
NET_VENDOR_PENSANDO
NET_VENDOR_QLOGIC
NET_VENDOR_BROCADE
NET_VENDOR_QUALCOMM
NET_VENDOR_RDC
NET_VENDOR_REALTEK
NET_VENDOR_RENESAS
NET_VENDOR_ROCKER
NET_VENDOR_SAMSUNG
NET_VENDOR_SEEQ
NET_VENDOR_SILAN
NET_VENDOR_SIS
NET_VENDOR_SMSC
NET_VENDOR_SOCIONEXT
NET_VENDOR_SOLARFLARE
NET_VENDOR_STMICRO
NET_VENDOR_SUN
NET_VENDOR_SYNOPSYS
NET_VENDOR_TEHUTI
NET_VENDOR_TI
NET_VENDOR_VERTEXCOM
NET_VENDOR_VIA
NET_VENDOR_WANGXUN
NET_VENDOR_WIZNET
NET_VENDOR_XILINX
FDDI
HIPPI
NET_SB1000
```
**Count: 70**

---

### 20. Obsolete Network Subsystems (Lines 325-339)
```
HAMRADIO
ISDN
WIMAX
CAN
NFC
INFINIBAND
CAIF
HSR
PHONET
IEEE802154
6LOWPAN
ATM
DECNET
LAPB
X25
```
**Count: 15**

---

### 21. Input Devices (Lines 345-348)
```
INPUT_JOYSTICK
INPUT_TABLET
INPUT_JOYDEV
GAMEPORT
```
**Count: 4**

---

### 22. Legacy Ports (Lines 354-356)
```
PARPORT
PCMCIA
FIREWIRE
```
**Count: 3**

---

### 23. Media/DVB Drivers (Lines 362-367)
```
DVB_CORE
MEDIA_ANALOG_TV_SUPPORT
MEDIA_DIGITAL_TV_SUPPORT
MEDIA_RADIO_SUPPORT
MEDIA_SDR_SUPPORT
MEDIA_TEST_SUPPORT
```
**Count: 6**

---

### 24. Specialized Hardware (Lines 373-381)
```
FPGA
GNSS
GREYBUS
SIOX
SLIMBUS
MOST
IIO
AUXDISPLAY
ACCESSIBILITY
```
**Count: 9**

---

### 25. Memory Hotplug (Lines 387-388)
```
MEMORY_HOTPLUG
MEMORY_HOTREMOVE
```
**Count: 2**

---

### 26. SCSI Controllers (Lines 394-412)
```
MEGARAID_NEWGEN
MEGARAID_SAS
FUSION
SCSI_AACRAID
SCSI_AIC7XXX
SCSI_AIC79XX
SCSI_MVSAS
SCSI_MVUMI
SCSI_MPT3SAS
SCSI_SYM53C8XX_2
SCSI_IPR
SCSI_QLA_FC
SCSI_QLA_ISCSI
SCSI_BNX2_ISCSI
SCSI_CXGB3_ISCSI
SCSI_CXGB4_ISCSI
SCSI_SMARTPQI
SCSI_HPSA
SCSI_UFSHCD
```
**Count: 19**

---

### 27. Filesystems (Lines 418-435)
```
ECRYPT_FS
CIFS
CIFS_DEBUG
9P_FS
AFS_FS
CEPH_FS
ORANGEFS_FS
GFS2_FS
OCFS2_FS
NILFS2_FS
REISERFS_FS
JFS_FS
HFS_FS
HFSPLUS_FS
MINIX_FS
ROMFS_FS
CRAMFS
SQUASHFS
```
**Count: 18**

---

### 28. VM Passthrough - VHOST/VFIO (Lines 441-445)
```
VHOST_MENU
VHOST_NET
VHOST_SCSI
VHOST_VSOCK
VFIO
```
**Count: 5**

---

### 29. SoundWire (Line 451)
```
SOUNDWIRE
```
**Count: 1**

---

### 30. Boot Logo (Lines 457-458)
```
LOGO
FB_BOOT_VESA_SUPPORT
```
**Count: 2**

---

### 31. NFS (Lines 464-466)
```
NFS_FS
NFSD
NFS_V4
```
**Count: 3**

---

### 32. Macintosh/Legacy Drivers (Lines 472-475)
```
MACINTOSH_DRIVERS
MAC_EMUMOUSEBTN
MAC_PARTITION
PATA_SIS
```
**Count: 4**

---

### 33. PCI Hotplug (Lines 481-483)
```
HOTPLUG_PCI
HOTPLUG_PCI_CPCI
HOTPLUG_PCI_SHPC
```
**Count: 3**

---

### 34. EDAC/ECC (Line 489)
```
EDAC
```
**Count: 1**

---

### 35. Staging Drivers (Lines 495-496)
```
STAGING
STAGING_MEDIA
```
**Count: 2**

---

### 36. Non-Dell Platform Drivers (Lines 502-504)
```
CHROME_PLATFORMS
SURFACE_PLATFORMS
X86_PLATFORM_DRIVERS_HP
```
**Count: 3**

---

### 37. IR Remote Control (Lines 510-512)
```
RC_CORE
LIRC
MEDIA_RC_SUPPORT
```
**Count: 3**

---

### 38. Legacy Wireless Extensions (Line 518)
```
CFG80211_WEXT
```
**Count: 1**

---

### 39. Samsung Battery (Line 524)
```
BATTERY_SAMSUNG_SDI
```
**Count: 1**

---

### 40. Disk Quotas (Line 530)
```
QUOTA
```
**Count: 1**

---

### 41. Hibernation (Line 536)
```
HIBERNATION
```
**Count: 1**

---

### 42. PC Speaker (Lines 542-544)
```
PCSPKR_PLATFORM
INPUT_PCSPKR
SND_PCSP
```
**Count: 3**

---

### 43. MPLS (Line 550)
```
MPLS
```
**Count: 1**

---

### 44. Network Switch/L3 (Lines 556-557)
```
NET_SWITCHDEV
NET_L3_MASTER_DEV
```
**Count: 2**

---

### 45. Legacy Syscalls (Lines 563-564)
```
SYSFS_SYSCALL
UID16
```
**Count: 2**

---

### 46. Proc Debug (Line 570)
```
PROC_KCORE
```
**Count: 1**

---

### 47. Performance Tuning - Disables (Lines 579-643)
```
CC_OPTIMIZE_FOR_SIZE
PREEMPT_NONE
PREEMPT
LIVEPATCH
NUMA
MEMCG_V1
CPUSETS_V1
MEMORY_BALLOON
BALLOON_COMPACTION
WATCHDOG
CRASH_DUMP
KEXEC_CORE
KEXEC
EXT4_DEBUG
XFS_DEBUG
BTRFS_DEBUG
F2FS_CHECK_FS
BPF_JIT_HARDENING
USERFAULTFD
NET_DROP_MONITOR
NET_FLOW_LIMIT
```
**Count: 21**

---

## Cross-Reference Analysis: Required vs Disabled Configs

### Summary
- **Required configs from HARDWARE_INVENTORY.md**: 107
- **Disabled configs in build.sh**: 322
- **Direct conflicts (same config name)**: 0
- **Related/functional conflicts**: 6

---

## Conflicts Identified

### CRITICAL: DisplayLink Support Broken (Lines 201-207)

**Section in build.sh:**
```bash
#######################################
# DISABLE DISPLAYLINK / USB DISPLAY
#######################################
echo "[*] Disabling DisplayLink drivers..."
./scripts/config --disable DRM_EVDI      # Line 204
./scripts/config --disable FB_UDLFB      # Line 205
./scripts/config --disable USB_UDL       # Line 206
./scripts/config --disable DRM_UDL       # Line 207
```

**Conflict Details:**

| Disabled Config | Line | Required For | Impact |
|----------------|------|--------------|--------|
| DRM_EVDI | 204 | DisplayLink EVDI driver | **CRITICAL** - EVDI module cannot load |
| FB_UDLFB | 205 | USB framebuffer | Alternate DisplayLink path broken |
| USB_UDL | 206 | USB DisplayLink | Legacy DisplayLink support |
| DRM_UDL | 207 | DRM DisplayLink | DRM-based DisplayLink |

**From HARDWARE_INVENTORY.md (Lines 274-296):**
> DisplayLink docks require:
> 1. **EVDI driver** (External Virtual Display Interface) - built out-of-tree
> ...
> CONFIG_MODULES=y
> CONFIG_MODULE_UNLOAD=y

**Resolution Required:** Remove or comment out lines 204-207. While EVDI is built out-of-tree, disabling these kernel configs may prevent proper DRM framework support for the EVDI module.

---

### WARNING: Docker SECCOMP Disabled (Lines 153-154)

**Section in build.sh:**
```bash
#######################################
# DISABLE SECURITY FRAMEWORKS
#######################################
echo "[*] Disabling security frameworks..."
./scripts/config --disable SECURITY_SELINUX
./scripts/config --disable SECURITY_APPARMOR
./scripts/config --disable SECCOMP         # Line 153
./scripts/config --disable SECCOMP_FILTER  # Line 154
```

**Conflict Details:**

| Disabled Config | Line | Docker Requirement | Impact |
|----------------|------|-------------------|--------|
| SECCOMP | 153 | Container syscall filtering | Containers run unconfined |
| SECCOMP_FILTER | 154 | BPF-based filtering | No fine-grained syscall control |

**From HARDWARE_INVENTORY.md:** Docker requirements do NOT list SECCOMP as mandatory, but it is used by default.

**Impact:**
- Docker will still work but all containers will need `--security-opt seccomp=unconfined`
- Alternatively, Docker can be configured with `"seccomp-profile": "unconfined"` in daemon.json
- This is acceptable for a performance-focused single-user laptop

**Resolution:** Acceptable if security is not a concern. Document the requirement to run Docker with `--security-opt seccomp=unconfined`.

---

## Required Configs from HARDWARE_INVENTORY.md

### Hardware Drivers (Must NOT be disabled)

| Category | Config | Status in build.sh |
|----------|--------|-------------------|
| **CPU** | CPU_FREQ | NOT disabled |
| | CPU_FREQ_GOV_PERFORMANCE | NOT disabled |
| | INTEL_PSTATE | NOT disabled |
| | INTEL_RAPL | NOT disabled |
| **GPU** | DRM | NOT disabled |
| | DRM_I915 | NOT disabled |
| | DRM_KMS_HELPER | NOT disabled |
| | FB_CORE | NOT disabled |
| **WiFi** | WLAN | NOT disabled |
| | WLAN_VENDOR_ATHEROS | NOT disabled |
| | ATH10K | NOT disabled |
| | ATH10K_PCI | NOT disabled |
| | CFG80211 | NOT disabled |
| | MAC80211 | NOT disabled |
| **Bluetooth** | BT | NOT disabled |
| | BT_HCIBTUSB | NOT disabled |
| **Storage** | BLK_DEV_NVME | NOT disabled |
| | NVME_CORE | NOT disabled |
| | SCSI | NOT disabled |
| **Audio** | SOUND | NOT disabled |
| | SND | NOT disabled |
| | SND_HDA_INTEL | NOT disabled |
| | SND_USB_AUDIO | NOT disabled |
| **USB** | USB | NOT disabled |
| | USB_XHCI_HCD | NOT disabled |
| | USB_NET_CDC_NCM | NOT disabled |
| **DisplayLink** | DRM | NOT disabled |
| | DRM_TTM | NOT disabled |
| | MODULES | NOT disabled |
| | MODULE_UNLOAD | NOT disabled |

### Docker Requirements (Must NOT be disabled)

| Category | Config | Status in build.sh |
|----------|--------|-------------------|
| **Namespaces** | NAMESPACES | NOT disabled |
| | UTS_NS | NOT disabled |
| | IPC_NS | NOT disabled |
| | PID_NS | NOT disabled |
| | USER_NS | NOT disabled |
| | NET_NS | NOT disabled |
| **Cgroups** | CGROUPS | NOT disabled |
| | CGROUP_CPUACCT | NOT disabled |
| | CGROUP_DEVICE | NOT disabled |
| | CGROUP_FREEZER | NOT disabled |
| | CGROUP_SCHED | NOT disabled |
| | MEMCG | NOT disabled |
| | BLK_CGROUP | NOT disabled |
| | CGROUP_PIDS | NOT disabled |
| **Filesystem** | OVERLAY_FS | NOT disabled |
| **Networking** | NETFILTER | NOT disabled |
| | BRIDGE | NOT disabled |
| | VETH | NOT disabled |
| | NF_NAT | NOT disabled |
| | IP_NF_IPTABLES | NOT disabled |
| **Block** | BLK_DEV_LOOP | NOT disabled |
| | BLK_DEV_DM | NOT disabled |
| **Security** | SECCOMP | **DISABLED (Line 153)** |
| | SECCOMP_FILTER | **DISABLED (Line 154)** |

---

## Verification Checklist

- [x] All required configs from HARDWARE_INVENTORY.md extracted (107 configs)
- [x] DRM_EVDI conflict confirmed at **Lines 204-207**
- [x] SECCOMP conflict with Docker confirmed at **Lines 153-154**
- [x] No other required configs are directly disabled
- [x] WLAN_VENDOR_ATHEROS correctly NOT disabled (WiFi works)
- [x] All Docker namespace/cgroup configs are NOT disabled
- [x] All DisplayLink-related USB configs (CDC_NCM, USB, etc.) are NOT disabled

---

## Additional Configs Recommended for Disabling

The following configs are currently enabled but can be safely disabled for additional performance gains without breaking Docker or DisplayLink:

### 1. BSD_PROCESS_ACCT / BSD_PROCESS_ACCT_V3
**Currently:** Enabled
**Justification:** BSD process accounting logs process information at exit. Not required by Docker or DisplayLink. Only useful for system auditing/accounting.
**Docker impact:** None - Docker does not require BSD process accounting
**DisplayLink impact:** None - unrelated to display/USB functionality
**Hardware inventory check:** Not mentioned

### 2. TASKSTATS / TASK_DELAY_ACCT / TASK_XACCT / TASK_IO_ACCOUNTING
**Currently:** Enabled
**Justification:** Extended task statistics and delay accounting. Only needed for advanced monitoring tools like iotop. Not required for basic Docker container operations.
**Docker impact:** Minimal - only affects `docker stats` precision for I/O, containers still work
**DisplayLink impact:** None
**Hardware inventory check:** Not mentioned

### 3. COREDUMP / ELF_CORE / DEV_COREDUMP
**Currently:** Enabled
**Justification:** Core dumps are for debugging crashed processes. Disabling saves memory and reduces attack surface.
**Docker impact:** None - Docker containers will still run, just won't generate core dumps on crash
**DisplayLink impact:** None
**Hardware inventory check:** Not mentioned

### 4. MAGIC_SYSRQ
**Currently:** Enabled
**Justification:** Magic SysRq key for emergency kernel commands. Slight security and performance overhead. Not needed for normal operation.
**Docker impact:** None
**DisplayLink impact:** None
**Hardware inventory check:** Not mentioned

### 5. RELAY
**Currently:** Enabled
**Justification:** Relay filesystem for kernel-to-userspace data transfer. Used by tracing and debugging tools which are already disabled.
**Docker impact:** None
**DisplayLink impact:** None
**Hardware inventory check:** Not mentioned

### 6. KALLSYMS
**Currently:** Enabled
**Justification:** Kernel symbol table in /proc/kallsyms. Useful for debugging but adds kernel size and potential security risk.
**Docker impact:** None - container networking and cgroups don't use it
**DisplayLink impact:** None
**Hardware inventory check:** Not mentioned

### 7. MEMTEST
**Currently:** Enabled
**Justification:** Memory testing at boot time. Only useful during hardware diagnostics, adds boot time overhead.
**Docker impact:** None
**DisplayLink impact:** None
**Hardware inventory check:** Not mentioned

### 8. KEXEC_FILE / KEXEC_SIG
**Currently:** Enabled (KEXEC_CORE already disabled but these remain)
**Justification:** Kexec file-based loading and signature verification. Not needed since KEXEC_CORE is disabled.
**Docker impact:** None
**DisplayLink impact:** None
**Hardware inventory check:** Not mentioned

### 9. ACPI_DEBUG
**Currently:** Enabled
**Justification:** ACPI debugging facilities. Adds code paths and slight overhead. Not needed for production use.
**Docker impact:** None
**DisplayLink impact:** None
**Hardware inventory check:** Not mentioned (ACPI core is required, but debug is not)

### 10. DMI_SYSFS
**Currently:** Enabled
**Justification:** Exposes DMI/SMBIOS information via sysfs. Rarely used, slight overhead.
**Docker impact:** None
**DisplayLink impact:** None
**Hardware inventory check:** Not mentioned

### Summary Table

| Config | Category | Docker Safe | DisplayLink Safe | In HW Inventory |
|--------|----------|-------------|------------------|-----------------|
| BSD_PROCESS_ACCT | Accounting | Yes | Yes | No |
| BSD_PROCESS_ACCT_V3 | Accounting | Yes | Yes | No |
| TASKSTATS | Accounting | Yes* | Yes | No |
| TASK_DELAY_ACCT | Accounting | Yes* | Yes | No |
| TASK_XACCT | Accounting | Yes* | Yes | No |
| TASK_IO_ACCOUNTING | Accounting | Yes* | Yes | No |
| COREDUMP | Debug | Yes | Yes | No |
| ELF_CORE | Debug | Yes | Yes | No |
| DEV_COREDUMP | Debug | Yes | Yes | No |
| MAGIC_SYSRQ | Debug | Yes | Yes | No |
| RELAY | Debug | Yes | Yes | No |
| KALLSYMS | Debug | Yes | Yes | No |
| MEMTEST | Debug | Yes | Yes | No |
| KEXEC_FILE | Recovery | Yes | Yes | No |
| KEXEC_SIG | Recovery | Yes | Yes | No |
| ACPI_DEBUG | Debug | Yes | Yes | No |
| DMI_SYSFS | Sysfs | Yes | Yes | No |

*TASKSTATS family: Docker stats command may show less I/O detail, but containers run normally.

---

## Commented Out Options (Not Active)

The following are in build.sh but commented out (lines 108-109, 37-38):
```
# RANDOMIZE_BASE        (ASLR - kept for minimal performance impact)
# RANDOMIZE_MEMORY      (ASLR - kept for minimal performance impact)
# CC_OPTIMIZE_FOR_PERFORMANCE  (for -O3 experiment)
# CC_OPTIMIZE_FOR_PERFORMANCE_O3 (for -O3 experiment)
```

---

## Summary Statistics

| Metric | Value |
|--------|-------|
| Total Active Disable Commands | 322 |
| Commented Out Disables | 3 |
| Categories | 47 |
| Largest Category | Ethernet Vendors (70) |
| Security-Related Disables | ~40 |
| Driver-Related Disables | ~200 |
| Subsystem Disables | ~80 |

---

## Quick Reference - All Disabled Configs (Alphabetical)

<details>
<summary>Click to expand full alphabetical list</summary>

```
6LOWPAN
9P_FS
ACCESSIBILITY
ACPI_DEBUGGER
AFS_FS
ATM
AUDIT
AUDITSYSCALL
AUXDISPLAY
BALLOON_COMPACTION
BATTERY_SAMSUNG_SDI
BPF_JIT_HARDENING
BTRFS_DEBUG
CAIF
CAN
CEPH_FS
CFG80211_WEXT
CHROME_PLATFORMS
CIFS
CIFS_DEBUG
CPUSETS_V1
CRAMFS
CRASH_DUMP
DEBUG_BUGVERBOSE
DEBUG_INFO
DEBUG_KERNEL
DEBUG_PREEMPT
DECNET
DRM_AMDGPU
DRM_AST
DRM_BOCHS
DRM_CIRRUS_QEMU
DRM_EVDI
DRM_I915_CAPTURE_ERROR
DRM_I915_COMPRESS_ERROR
DRM_MGAG200
DRM_NOUVEAU
DRM_QXL
DRM_RADEON
DRM_UDL
DRM_VIRTIO_GPU
DRM_VMWGFX
DVB_CORE
ECRYPT_FS
EDAC
EXT4_DEBUG
F2FS_CHECK_FS
FB_BOOT_VESA_SUPPORT
FB_UDLFB
FDDI
FIREWIRE
FORTIFY_SOURCE
FPGA
FTRACE
FUNCTION_TRACER
FUSION
GAMEPORT
GFS2_FS
GNSS
GREYBUS
HAMRADIO
HARDENED_USERCOPY
HFS_FS
HFSPLUS_FS
HIBERNATION
HIPPI
HOTPLUG_PCI
HOTPLUG_PCI_CPCI
HOTPLUG_PCI_SHPC
HSR
HYPERVISOR_GUEST
IEEE802154
IIO
INFINIBAND
INIT_ON_ALLOC_DEFAULT_ON
INIT_ON_FREE_DEFAULT_ON
INIT_STACK_ALL_ZERO
INPUT_JOYSTICK
INPUT_JOYDEV
INPUT_PCSPKR
INPUT_TABLET
ISDN
JFS_FS
KASAN
KCSAN
KEXEC
KEXEC_CORE
KPROBES
KVM
KVM_AMD
KVM_GUEST
KVM_INTEL
LAPB
LATENCYTOP
LIRC
LIVEPATCH
LOGO
LTO_NONE
MAC_EMUMOUSEBTN
MAC_PARTITION
MACINTOSH_DRIVERS
MEDIA_ANALOG_TV_SUPPORT
MEDIA_DIGITAL_TV_SUPPORT
MEDIA_RADIO_SUPPORT
MEDIA_RC_SUPPORT
MEDIA_SDR_SUPPORT
MEDIA_TEST_SUPPORT
MEGARAID_NEWGEN
MEGARAID_SAS
MEMCG_V1
MEMORY_BALLOON
MEMORY_HOTPLUG
MEMORY_HOTREMOVE
MINIX_FS
MITIGATION_GDS
MITIGATION_IBPB_ENTRY
MITIGATION_IBRS_ENTRY
MITIGATION_L1TF
MITIGATION_MDS
MITIGATION_MMIO_STALE_DATA
MITIGATION_PAGE_TABLE_ISOLATION
MITIGATION_RETPOLINE
MITIGATION_RFDS
MITIGATION_SLS
MITIGATION_SPECTRE_BHI
MITIGATION_SPECTRE_V1
MITIGATION_SPECTRE_V2
MITIGATION_SRBDS
MITIGATION_SSB
MITIGATION_TAA
MITIGATION_TSA
MITIGATION_VMSCAPE
MODULE_SIG
MODULE_SIG_ALL
MODULE_SRCVERSION_ALL
MODVERSIONS
MOST
MPLS
NET_DROP_MONITOR
NET_FLOW_LIMIT
NET_L3_MASTER_DEV
NET_SB1000
NET_SWITCHDEV
NET_VENDOR_3COM
NET_VENDOR_ADAPTEC
NET_VENDOR_AGERE
NET_VENDOR_ALACRITECH
NET_VENDOR_ALTEON
NET_VENDOR_AMAZON
NET_VENDOR_AMD
NET_VENDOR_AQUANTIA
NET_VENDOR_ARC
NET_VENDOR_ASIX
NET_VENDOR_ATHEROS
NET_VENDOR_BROADCOM
NET_VENDOR_BROCADE
NET_VENDOR_CADENCE
NET_VENDOR_CAVIUM
NET_VENDOR_CHELSIO
NET_VENDOR_CISCO
NET_VENDOR_CORTINA
NET_VENDOR_DAVICOM
NET_VENDOR_DEC
NET_VENDOR_DLINK
NET_VENDOR_EMULEX
NET_VENDOR_ENGLEDER
NET_VENDOR_EZCHIP
NET_VENDOR_FUNGIBLE
NET_VENDOR_GOOGLE
NET_VENDOR_HUAWEI
NET_VENDOR_INTEL
NET_VENDOR_LITEX
NET_VENDOR_MARVELL
NET_VENDOR_MELLANOX
NET_VENDOR_MICREL
NET_VENDOR_MICROCHIP
NET_VENDOR_MICROSEMI
NET_VENDOR_MICROSOFT
NET_VENDOR_MYRI
NET_VENDOR_NATSEMI
NET_VENDOR_NETERION
NET_VENDOR_NETRONOME
NET_VENDOR_NI
NET_VENDOR_NVIDIA
NET_VENDOR_OKI
NET_VENDOR_PACKET_ENGINES
NET_VENDOR_PENSANDO
NET_VENDOR_QLOGIC
NET_VENDOR_QUALCOMM
NET_VENDOR_RDC
NET_VENDOR_REALTEK
NET_VENDOR_RENESAS
NET_VENDOR_ROCKER
NET_VENDOR_SAMSUNG
NET_VENDOR_SEEQ
NET_VENDOR_SILAN
NET_VENDOR_SIS
NET_VENDOR_SMSC
NET_VENDOR_SOCIONEXT
NET_VENDOR_SOLARFLARE
NET_VENDOR_STMICRO
NET_VENDOR_SUN
NET_VENDOR_SYNOPSYS
NET_VENDOR_TEHUTI
NET_VENDOR_TI
NET_VENDOR_VERTEXCOM
NET_VENDOR_VIA
NET_VENDOR_WANGXUN
NET_VENDOR_WIZNET
NET_VENDOR_XILINX
NFC
NFS_FS
NFS_V4
NFSD
NILFS2_FS
NUMA
OCFS2_FS
ORANGEFS_FS
PAGE_POISONING
PARAVIRT
PARAVIRT_SPINLOCKS
PARAVIRT_XXL
PARPORT
PATA_SIS
PCMCIA
PCSPKR_PLATFORM
PHONET
PM_ADVANCED_DEBUG
PM_DEBUG
PM_SLEEP_DEBUG
PM_TRACE
PM_TRACE_RTC
PREEMPT
PREEMPT_NONE
PRINTK_CALLER
PRINTK_TIME
PROC_KCORE
PROFILING
QUOTA
RANDOMIZE_KSTACK_OFFSET_DEFAULT
RC_CORE
REISERFS_FS
ROMFS_FS
SCHED_DEBUG
SCHED_INFO
SCHED_STACK_END_CHECK
SCHEDSTATS
SCSI_AACRAID
SCSI_AIC79XX
SCSI_AIC7XXX
SCSI_BNX2_ISCSI
SCSI_CXGB3_ISCSI
SCSI_CXGB4_ISCSI
SCSI_HPSA
SCSI_IPR
SCSI_MPT3SAS
SCSI_MVSAS
SCSI_MVUMI
SCSI_QLA_FC
SCSI_QLA_ISCSI
SCSI_SMARTPQI
SCSI_SYM53C8XX_2
SCSI_UFSHCD
SECCOMP
SECCOMP_FILTER
SECURITY_APPARMOR
SECURITY_SELINUX
SIOX
SLAB_FREELIST_HARDENED
SLAB_FREELIST_RANDOM
SLIMBUS
SND_PCSP
SOUNDWIRE
SQUASHFS
STACK_TRACER
STACKPROTECTOR
STACKPROTECTOR_STRONG
STAGING
STAGING_MEDIA
SURFACE_PLATFORMS
SYMBOLIC_ERRNAME
SYSFS_SYSCALL
TRACING
UBSAN
UID16
USB_UDL
USERFAULTFD
VFIO
VHOST_MENU
VHOST_NET
VHOST_SCSI
VHOST_VSOCK
VIRTUALIZATION
WATCHDOG
WIMAX
WLAN_VENDOR_ADMTEK
WLAN_VENDOR_ATMEL
WLAN_VENDOR_BROADCOM
WLAN_VENDOR_INTEL
WLAN_VENDOR_INTERSIL
WLAN_VENDOR_MARVELL
WLAN_VENDOR_MEDIATEK
WLAN_VENDOR_MICROCHIP
WLAN_VENDOR_PURELIFI
WLAN_VENDOR_QUANTENNA
WLAN_VENDOR_RALINK
WLAN_VENDOR_REALTEK
WLAN_VENDOR_RSI
WLAN_VENDOR_SILABS
WLAN_VENDOR_ST
WLAN_VENDOR_TI
WLAN_VENDOR_ZYDAS
X25
X86_PLATFORM_DRIVERS_HP
XEN
XEN_512GB
XEN_PV
XEN_PVH
XEN_PVHVM
XFS_DEBUG
ZERO_CALL_USED_REGS
CC_OPTIMIZE_FOR_SIZE
```

</details>
