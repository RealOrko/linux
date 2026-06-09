# Dell Laptop Hardware Inventory for Minimal Kernel

## System Overview
- **Laptop**: Dell (Subsystem ID: 1028:075B)
- **CPU**: Intel Core i7-7500U (Kaby Lake)
- **Architecture**: x86_64
- **Cores**: 2 cores, 4 threads
- **Socket**: 1

---

## CPU Details

| Property | Value |
|----------|-------|
| Model | Intel Core i7-7500U @ 2.70GHz |
| CPU Family | 6 |
| Model Number | 142 |
| Stepping | 9 |
| Max Frequency | 3500 MHz |
| Min Frequency | 400 MHz |
| L1d Cache | 64 KiB (2 instances) |
| L1i Cache | 64 KiB (2 instances) |
| L2 Cache | 512 KiB (2 instances) |
| L3 Cache | 4 MiB |
| Virtualization | VT-x (disabled for performance) |

### CPU Features
- SSE4.1, SSE4.2, AVX, AVX2
- AES-NI, PCLMULQDQ
- Intel Hardware P-states (HWP)
- Intel PT (Processor Trace)

### Required Kernel Options for CPU
```
CONFIG_MCORE2=y              # Kaby Lake optimization (Core 2 family)
CONFIG_X86_NATIVE_CPU=y      # Native CPU optimizations (if available)
CONFIG_CPU_FREQ=y            # CPU frequency scaling
CONFIG_CPU_FREQ_GOV_PERFORMANCE=y
CONFIG_INTEL_PSTATE=y        # Intel P-state driver
CONFIG_INTEL_RAPL=y          # Running Average Power Limit
```

---

## GPU (Integrated Graphics)

| Property | Value |
|----------|-------|
| Device | Intel HD Graphics 620 |
| PCI ID | 8086:5916 |
| Driver | i915 |
| PCI Slot | 0000:00:02.0 |

### Required Kernel Options for GPU
```
CONFIG_DRM=y
CONFIG_DRM_I915=y
CONFIG_DRM_KMS_HELPER=y
CONFIG_FB_CORE=y
CONFIG_FRAMEBUFFER_CONSOLE=y
```

---

## WiFi Adapter

| Property | Value |
|----------|-------|
| Chipset | Qualcomm Atheros QCA6174 |
| PCI ID | 168C:003E |
| Subsystem | 1A56:1535 (Killer Wireless) |
| Driver | ath10k_pci |
| PCI Slot | 0000:3a:00.0 |
| Interface | wlp58s0 |

### Required Kernel Options for WiFi
```
CONFIG_WLAN=y
CONFIG_WLAN_VENDOR_ATHEROS=y
CONFIG_ATH_COMMON=y
CONFIG_ATH10K=y
CONFIG_ATH10K_PCI=y
CONFIG_ATH10K_CE=y
CONFIG_CFG80211=y
CONFIG_MAC80211=y
CONFIG_WIRELESS=y
CONFIG_RFKILL=y
```

---

## Bluetooth

| Property | Value |
|----------|-------|
| Device | Atheros AR3012 (integrated with WiFi) |
| USB ID | 0cf3:e300 |
| Driver | btusb |

### Required Kernel Options for Bluetooth
```
CONFIG_BT=y
CONFIG_BT_HCIBTUSB=y
CONFIG_BT_HCIBTUSB_ATH3K=y
```

---

## USB Ethernet (DisplayLink)

| Property | Value |
|----------|-------|
| Device | DisplayLink USB Dock Ethernet |
| USB ID | 17e9:436e |
| Driver | cdc_ncm |
| Interface | enx9cebe840e1a1 |

### Required Kernel Options for USB Ethernet
```
CONFIG_USB_NET_DRIVERS=y
CONFIG_USB_NET_CDC_NCM=y
CONFIG_USB_USBNET=y
```

---

## Storage

### NVMe SSD

| Property | Value |
|----------|-------|
| Device | Toshiba NVMe SSD |
| PCI ID | 1179:0115 |
| Driver | nvme |
| PCI Slot | 0000:3c:00.0 |

### Required Kernel Options for Storage
```
CONFIG_BLK_DEV_NVME=y
CONFIG_NVME_CORE=y
CONFIG_SCSI=y                # For USB mass storage
CONFIG_BLK_DEV_SD=y
CONFIG_USB_STORAGE=y
```

---

## Audio

| Property | Value |
|----------|-------|
| Device | Intel Sunrise Point-LP HD Audio |
| PCI ID | 8086:9D71 |
| Driver | snd_hda_intel |
| PCI Slot | 0000:00:1f.3 |

### USB Audio (DisplayLink)
| Property | Value |
|----------|-------|
| Device | DisplayLink USB Audio |
| USB ID | 17e9:436e |
| Driver | snd-usb-audio |

### USB Microphone (Blue Yeti)
| Property | Value |
|----------|-------|
| Device | Blue Yeti Stereo Microphone |
| USB ID | b58e:9e84 |
| Driver | snd-usb-audio |
| Connection | Via Dell D3100 dock USB hub |

### Required Kernel Options for Audio
```
CONFIG_SOUND=y
CONFIG_SND=y
CONFIG_SND_PCI=y
CONFIG_SND_HDA_INTEL=y
CONFIG_SND_HDA_CODEC_REALTEK=y
CONFIG_SND_USB_AUDIO=m
```

---

## USB Controllers

| Property | Value |
|----------|-------|
| Device | Intel Sunrise Point-LP USB 3.0 xHCI |
| PCI ID | 8086:9D2F |
| Driver | xhci_hcd |
| PCI Slot | 0000:00:14.0 |

### Required Kernel Options for USB
```
CONFIG_USB_SUPPORT=y
CONFIG_USB=y
CONFIG_USB_XHCI_HCD=y
CONFIG_USB_XHCI_PCI=y
CONFIG_USB_EHCI_HCD=y         # Fallback for USB 2.0
CONFIG_USB_HID=y
CONFIG_HID=y
CONFIG_HID_GENERIC=y
```

---

## Card Reader

| Property | Value |
|----------|-------|
| Device | Realtek RTS525A PCI Express Card Reader |
| PCI ID | 10EC:525A |
| Driver | rtsx_pci |
| PCI Slot | 0000:3b:00.0 |

### Required Kernel Options (OPTIONAL - can be disabled)
```
CONFIG_MISC_RTSX_PCI=y
CONFIG_MMC_REALTEK_PCI=y
```

---

## Webcam

| Property | Value |
|----------|-------|
| Device | Microdia Integrated Webcam |
| USB ID | 0c45:670c |
| Driver | uvcvideo |

### Required Kernel Options for Webcam
```
CONFIG_MEDIA_SUPPORT=y
CONFIG_MEDIA_USB_SUPPORT=y
CONFIG_USB_VIDEO_CLASS=y
CONFIG_VIDEO_V4L2=y
```

---

## Platform/Chipset Support

### Thermal Management
| Property | Value |
|----------|-------|
| Device | Intel Processor Thermal |
| PCI ID | 8086:1903 |
| Driver | proc_thermal |

### I2C/SMBus
| Device | PCI ID | Driver |
|--------|--------|--------|
| Intel I2C | 8086:9D60 | intel-lpss |
| Intel SMBus | 8086:9D23 | i801_smbus |

### Management Engine
| Property | Value |
|----------|-------|
| Device | Intel MEI |
| PCI ID | 8086:9D3A |
| Driver | mei_me |

### Required Kernel Options for Platform
```
CONFIG_ACPI=y
CONFIG_X86_PLATFORM_DRIVERS_DELL=y
CONFIG_DELL_LAPTOP=y
CONFIG_DELL_WMI=y
CONFIG_INTEL_PCH_THERMAL=y
CONFIG_INTEL_RAPL=y
CONFIG_I2C=y
CONFIG_I2C_I801=y
CONFIG_INTEL_LPSS=y
CONFIG_INTEL_LPSS_PCI=y
```

---

## DisplayLink Requirements

DisplayLink docks require:
1. **EVDI driver** (External Virtual Display Interface) - built out-of-tree
2. **DRM core** - for display management
3. **USB support** - for dock connectivity
4. **CDC NCM** - for USB networking

### Required Kernel Options for DisplayLink
```
CONFIG_DRM=y
CONFIG_DRM_KMS_HELPER=y
CONFIG_DRM_TTM=y              # May be needed for EVDI
CONFIG_FB_CORE=y
CONFIG_USB=y
CONFIG_USB_NET_CDC_NCM=y
CONFIG_SND_USB_AUDIO=y        # For audio through dock

# EVDI is built out-of-tree from ~/code/evdi
# The kernel needs module loading support
CONFIG_MODULES=y
CONFIG_MODULE_UNLOAD=y
```

---

## Docker Requirements

Docker requires the following kernel features:

### Namespaces
```
CONFIG_NAMESPACES=y
CONFIG_UTS_NS=y
CONFIG_IPC_NS=y
CONFIG_PID_NS=y
CONFIG_USER_NS=y
CONFIG_NET_NS=y
```

### Cgroups
```
CONFIG_CGROUPS=y
CONFIG_CGROUP_CPUACCT=y
CONFIG_CGROUP_DEVICE=y
CONFIG_CGROUP_FREEZER=y
CONFIG_CGROUP_SCHED=y
CONFIG_MEMCG=y
CONFIG_BLK_CGROUP=y
CONFIG_CGROUP_PIDS=y
CONFIG_CGROUP_PERF=y
```

### Filesystem (OverlayFS for storage driver)
```
CONFIG_OVERLAY_FS=y
```

### Networking
```
CONFIG_NETFILTER=y
CONFIG_NETFILTER_ADVANCED=y
CONFIG_NETFILTER_XTABLES=y
CONFIG_NETFILTER_XT_MATCH_CONNTRACK=y
CONFIG_NETFILTER_XT_MATCH_ADDRTYPE=y
CONFIG_NF_CONNTRACK=y
CONFIG_NF_NAT=y
CONFIG_IP_NF_NAT=y
CONFIG_IP_NF_FILTER=y
CONFIG_IP_NF_TARGET_MASQUERADE=y
CONFIG_IP_NF_IPTABLES=y
CONFIG_BRIDGE=y
CONFIG_BRIDGE_NETFILTER=y
CONFIG_VETH=y
CONFIG_NET_IPVLAN=y           # Optional but useful
CONFIG_MACVLAN=y              # Optional but useful
CONFIG_VLAN_8021Q=y           # Optional
```

### Block Device
```
CONFIG_BLK_DEV_LOOP=y
CONFIG_BLK_DEV_DM=y            # Device mapper
CONFIG_DM_THIN_PROVISIONING=y  # For thin pools (optional)
```

### Misc Docker Requirements
```
CONFIG_POSIX_MQUEUE=y
CONFIG_KEYS=y
CONFIG_CRYPTO=y
CONFIG_CRYPTO_AEAD=y
CONFIG_CRYPTO_GCM=y
CONFIG_CRYPTO_SEQIV=y
CONFIG_CRYPTO_GHASH=y
```

---

## Current Kernel Config Baseline

| Metric | Count |
|--------|-------|
| Enabled (=y) | 2125 |
| Modules (=m) | 2 |
| Total CONFIG lines | 2272 |
| Total file lines | 7359 |

---

## Hardware Not Present (Safe to Disable)

- AMD/Radeon/NVIDIA GPUs
- All WiFi vendors except Atheros
- All Ethernet vendors (using USB networking only)
- Firewire (IEEE 1394)
- PCMCIA/CardBus
- Parallel port
- ISDN, ATM, X.25
- Infiniband
- Amateur Radio
- NFC
- CAN bus
- DVB/TV tuners
- Most SCSI controllers (keeping USB mass storage)
- All server-class RAID controllers
- KVM/QEMU (virtualization disabled)
- Xen hypervisor
- VMware guest drivers
- All non-Dell platform drivers

---

## Summary of Required Drivers

| Category | Driver | Status |
|----------|--------|--------|
| CPU | intel_pstate, intel_rapl | Required |
| GPU | i915 | Required |
| WiFi | ath10k_pci | Required |
| Bluetooth | btusb | Required |
| Storage | nvme | Required |
| Audio | snd_hda_intel | Required |
| USB Audio | snd-usb-audio | Required (DisplayLink) |
| USB | xhci_hcd | Required |
| USB Net | cdc_ncm | Required (DisplayLink) |
| USB HID | usbhid | Required |
| Webcam | uvcvideo | Required |
| Card Reader | rtsx_pci | Optional |
| EVDI | evdi (out-of-tree) | Required (DisplayLink) |
