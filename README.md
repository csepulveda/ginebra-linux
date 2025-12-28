# Ginebra Linux

![Ginebra-Linux](./logo.png)
![Terminal](./terminal.png)

```
       /\_____/\
      /  o   o  \      A minimalist Linux distribution
     ( ==  ^  == )     that fits on two 1.44MB floppy disks
      )         (
     (           )     ~ meow ~
    ( (  )   (  ) )
   (__(__)___(__)__)
```



**Ginebra Linux** is a fork of [Floppinux](https://github.com/w84death/floppinux) that extends the original concept using **two floppy disks**:

- **Floppy 1 (boot)**: Contains the kernel (`bzImage`) and SYSLINUX
- **Floppy 2 (rootfs)**: ext2 filesystem with BusyBox, kernel modules and network support

The system boots from the first floppy, gives you 30 seconds to swap to the second one, and then copies everything to RAM to run entirely from memory.

## Features

- Linux Kernel 6.14.x compiled for i486
- BusyBox 1.36.1 (static build with musl)
- Network support (RTL8139 driver)
- Loadable kernel modules
- System runs 100% from RAM after boot
- Ideal for retro hardware or virtual machines

## Requirements

- Ubuntu Linux (for compilation)
- ~3GB of disk space
- Packages: `build-essential`, `flex`, `bison`, `libncurses-dev`, `libelf-dev`, `libssl-dev`, `bc`, `syslinux`, `mtools`

```bash
sudo apt update
sudo apt install build-essential flex bison libncurses-dev libelf-dev libssl-dev bc syslinux mtools dosfstools e2fsprogs
```

## Project Structure

```
ginebra-linux/
├── linux/                    # Kernel source code
├── busybox-1_36_1/          # BusyBox source code
├── filesystem/              # Root filesystem
│   ├── bin/                 # Commands (symlinks to busybox)
│   ├── sbin/                # System commands
│   ├── etc/init.d/rc        # Boot script
│   ├── lib/modules/         # Kernel modules
│   └── welcome              # ASCII banner
├── i486-linux-musl-cross/   # Cross-compilation toolchain
├── repo/                    # Precompiled binaries and build scripts
│   ├── bash                 # GNU Bash static binary
│   ├── links                # Links browser static binary
│   ├── build-bash.sh        # Script to build bash
│   └── build-links.sh       # Script to build links
├── bzImage                  # Compiled kernel
├── floppy1-boot.img         # Boot floppy image
├── floppy2-rootfs.img       # Rootfs floppy image
└── syslinux.cfg             # Bootloader configuration
```

## Building

### 1. Download Toolchain

```bash
wget https://musl.cc/i486-linux-musl-cross.tgz
tar xzf i486-linux-musl-cross.tgz
export PATH="$PWD/i486-linux-musl-cross/bin:$PATH"
```

### 2. Build the Kernel

#### 2.1 Download the kernel

```bash
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.14.11.tar.xz
tar xf linux-6.14.11.tar.xz
mv linux-6.14.11 linux
cd linux
```

#### 2.2 Configuration from tinyconfig

We start from `tinyconfig` (the most minimal configuration) and enable only what's necessary:

```bash
cd linux

# Start from tinyconfig
make ARCH=x86 tinyconfig

# ============================================
# ARCHITECTURE AND CPU (i486)
# ============================================
scripts/config --enable CONFIG_M486
scripts/config --disable CONFIG_64BIT

# ============================================
# KERNEL COMPRESSION (XZ for minimum size)
# ============================================
scripts/config --disable CONFIG_KERNEL_GZIP
scripts/config --enable CONFIG_KERNEL_XZ

# ============================================
# INITRD / INITRAMFS
# ============================================
scripts/config --enable CONFIG_BLK_DEV_INITRD
scripts/config --disable CONFIG_RD_GZIP
scripts/config --disable CONFIG_RD_BZIP2
scripts/config --disable CONFIG_RD_LZMA
scripts/config --enable CONFIG_RD_XZ
scripts/config --disable CONFIG_RD_LZO
scripts/config --disable CONFIG_RD_LZ4
scripts/config --disable CONFIG_RD_ZSTD

# ============================================
# SIZE OPTIMIZATION
# ============================================
scripts/config --disable CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE
scripts/config --enable CONFIG_CC_OPTIMIZE_FOR_SIZE
scripts/config --enable CONFIG_SLUB_TINY

# ============================================
# KERNEL MODULES
# ============================================
scripts/config --enable CONFIG_MODULES
scripts/config --enable CONFIG_MODULE_UNLOAD

# ============================================
# BLOCK DEVICES
# ============================================
scripts/config --enable CONFIG_BLOCK
scripts/config --enable CONFIG_BLK_DEV_FD
scripts/config --enable CONFIG_BLK_DEV_RAM
scripts/config --set-val CONFIG_BLK_DEV_RAM_COUNT 1
scripts/config --set-val CONFIG_BLK_DEV_RAM_SIZE 4096
scripts/config --enable CONFIG_DEVTMPFS

# ============================================
# FILESYSTEMS
# ============================================
scripts/config --enable CONFIG_EXT2_FS
scripts/config --enable CONFIG_FAT_FS
scripts/config --enable CONFIG_MSDOS_FS
scripts/config --enable CONFIG_PROC_FS
scripts/config --enable CONFIG_PROC_SYSCTL
scripts/config --enable CONFIG_SYSFS
scripts/config --enable CONFIG_NLS
scripts/config --enable CONFIG_NLS_CODEPAGE_437

# ============================================
# NETWORKING
# ============================================
scripts/config --enable CONFIG_NET
scripts/config --enable CONFIG_INET
scripts/config --enable CONFIG_UNIX
scripts/config --disable CONFIG_IPV6
scripts/config --enable CONFIG_NETDEVICES
scripts/config --enable CONFIG_ETHERNET
scripts/config --enable CONFIG_NET_VENDOR_REALTEK
scripts/config --module CONFIG_8139TOO
scripts/config --enable CONFIG_8139TOO_PIO
scripts/config --module CONFIG_MII
scripts/config --module CONFIG_CRC16

# ============================================
# PCI
# ============================================
scripts/config --enable CONFIG_PCI
scripts/config --enable CONFIG_PCI_GOANY
scripts/config --enable CONFIG_PCI_BIOS
scripts/config --enable CONFIG_PCI_DIRECT

# ============================================
# INPUT / KEYBOARD / CONSOLE
# ============================================
scripts/config --enable CONFIG_INPUT
scripts/config --enable CONFIG_INPUT_KEYBOARD
scripts/config --enable CONFIG_KEYBOARD_ATKBD
scripts/config --enable CONFIG_SERIO
scripts/config --enable CONFIG_SERIO_I8042
scripts/config --enable CONFIG_SERIO_LIBPS2
scripts/config --enable CONFIG_TTY
scripts/config --enable CONFIG_VT
scripts/config --enable CONFIG_VT_CONSOLE
scripts/config --enable CONFIG_VGA_CONSOLE

# ============================================
# EXECUTABLE FORMATS
# ============================================
scripts/config --enable CONFIG_BINFMT_ELF
scripts/config --enable CONFIG_BINFMT_SCRIPT

# ============================================
# EXPERT OPTIONS (needed to access others)
# ============================================
scripts/config --enable CONFIG_EXPERT
scripts/config --enable CONFIG_PRINTK
scripts/config --enable CONFIG_POSIX_TIMERS

# ============================================
# EEPROM (required by 8139too)
# ============================================
scripts/config --enable CONFIG_EEPROM_93CX6

# ============================================
# MISC
# ============================================
scripts/config --enable CONFIG_MICROCODE
scripts/config --set-val CONFIG_HZ 250
scripts/config --enable CONFIG_PERF_EVENTS

# ============================================
# DISABLE UNNECESSARY FEATURES
# ============================================
scripts/config --disable CONFIG_SMP
scripts/config --disable CONFIG_MULTIUSER
scripts/config --disable CONFIG_SWAP
scripts/config --disable CONFIG_BUG
scripts/config --disable CONFIG_KALLSYMS
scripts/config --disable CONFIG_FUTEX
scripts/config --disable CONFIG_EPOLL
scripts/config --disable CONFIG_SIGNALFD
scripts/config --disable CONFIG_TIMERFD
scripts/config --disable CONFIG_EVENTFD
scripts/config --disable CONFIG_SHMEM
scripts/config --disable CONFIG_AIO
scripts/config --disable CONFIG_IO_URING
scripts/config --disable CONFIG_ADVISE_SYSCALLS
scripts/config --disable CONFIG_MEMBARRIER
scripts/config --disable CONFIG_CPU_MITIGATIONS
scripts/config --disable CONFIG_HIGH_RES_TIMERS
scripts/config --disable CONFIG_ACPI
scripts/config --disable CONFIG_SUSPEND
scripts/config --disable CONFIG_PM
scripts/config --disable CONFIG_USB_SUPPORT
scripts/config --disable CONFIG_SOUND
scripts/config --disable CONFIG_SCSI
scripts/config --disable CONFIG_ATA
scripts/config --disable CONFIG_DRM
scripts/config --disable CONFIG_FB
scripts/config --disable CONFIG_WIRELESS
scripts/config --disable CONFIG_WLAN
scripts/config --disable CONFIG_CRYPTO
scripts/config --disable CONFIG_VIRTUALIZATION
scripts/config --disable CONFIG_HYPERVISOR_GUEST
scripts/config --disable CONFIG_FW_LOADER
scripts/config --disable CONFIG_DEBUG_FS
scripts/config --disable CONFIG_MAGIC_SYSRQ
scripts/config --disable CONFIG_FTRACE
scripts/config --disable CONFIG_COREDUMP
scripts/config --disable CONFIG_UNIX98_PTYS
scripts/config --disable CONFIG_LEGACY_PTYS
scripts/config --disable CONFIG_INPUT_MOUSE

# Resolve dependencies automatically
make ARCH=x86 olddefconfig
```

#### 2.3 Build kernel and modules

```bash
# Build kernel
make ARCH=x86 bzImage -j$(nproc)

# Check size (should be less than ~900KB)
du -ks arch/x86/boot/bzImage

# Clean old modules and rebuild
find . -name "*.ko" -delete
make ARCH=x86 modules -j$(nproc)
```

#### 2.4 Interactive configuration (optional)

If you need to adjust options manually:

```bash
make ARCH=x86 menuconfig
```

### 3. Build BusyBox

```bash
cd busybox-1_36_1

# Configure (use existing config or menuconfig)
make ARCH=x86 olddefconfig
# make ARCH=x86 menuconfig

# Build and install
make ARCH=x86 -j$(nproc)
make ARCH=x86 install

# Copy to filesystem
sudo rsync -av _install/ ../filesystem/
```

### 4. Create Mount Points

```bash
sudo mkdir -p /mnt/floppy1 /mnt/floppy2
```

### 5. Update Floppy 1 (Boot)

```bash
cd linux

# Mount boot image
sudo mount -o loop ../floppy1-boot.img /mnt/floppy1

# Copy kernel
sudo cp arch/x86/boot/bzImage /mnt/floppy1/bzImage

# Check space
df -k /mnt/floppy1

# Unmount
sudo umount /mnt/floppy1
```

### 6. Update Floppy 2 (RootFS)

```bash
cd linux

# Get kernel version
KVER=$(make kernelrelease)
echo "Kernel version: $KVER"

# Prepare modules directory
sudo mkdir -p ../filesystem/lib/modules/$KVER
sudo rm -fr ../filesystem/lib/modules/$KVER/*

# Copy compiled modules
find . -name "*.ko" | xargs -I {} sudo cp {} ../filesystem/lib/modules/$KVER

# Generate module dependencies
sudo depmod -b ../filesystem -a $KVER

# Verify installed modules
sudo find ../filesystem/lib/modules/$KVER

# Mount rootfs image
sudo mount -o loop ../floppy2-rootfs.img /mnt/floppy2

# Sync filesystem
sudo rsync -av ../filesystem/ /mnt/floppy2/

# Check space
df -k /mnt/floppy2

# Unmount
sudo umount /mnt/floppy2
```

### 7. Edit SYSLINUX Configuration (Optional)

```bash
# Mount boot floppy
sudo mount -o loop floppy1-boot.img /mnt/floppy1

# Edit configuration
sudo vim syslinux.cfg

# Copy to floppy
sudo cp syslinux.cfg /mnt/floppy1/

# Unmount
sudo umount /mnt/floppy1
```

## SYSLINUX Configuration

The `syslinux.cfg` file for the two-floppy system:

```
DEFAULT ginebra
PROMPT 1
TIMEOUT 5

LABEL ginebra
SAY [ GINEBRA LINUX - 30 seconds to swap the disk ]
KERNEL bzImage
APPEND root=/dev/fd0 rootfstype=ext2 rootdelay=30 rw console=tty0 init=/etc/init.d/rc tsc=unstable
```

**Important parameters:**
- `root=/dev/fd0` - Use floppy drive as root
- `rootfstype=ext2` - ext2 filesystem
- `rootdelay=30` - Wait 30 seconds to swap disk
- `init=/etc/init.d/rc` - Custom init script

## Testing with QEMU

```bash
# With two simulated physical floppies
qemu-system-i386 -m 32 \
    -drive file=floppy1-boot.img,format=raw,if=floppy,index=0 \
    -drive file=floppy2-rootfs.img,format=raw,if=floppy,index=1 \
    -boot a

# With network (RTL8139)
qemu-system-i386 -m 32 \
    -drive file=floppy1-boot.img,format=raw,if=floppy,index=0 \
    -drive file=floppy2-rootfs.img,format=raw,if=floppy,index=1 \
    -boot a \
    -netdev user,id=net0 \
    -device rtl8139,netdev=net0
```

## Writing to Real Floppies

```bash
# Floppy 1 (boot)
sudo dd if=floppy1-boot.img of=/dev/fd0 bs=1024

# Floppy 2 (rootfs)
sudo dd if=floppy2-rootfs.img of=/dev/fd0 bs=1024
```

## Init Script (rc)

The `/etc/init.d/rc` script performs:

1. Mounts `/proc`, `/sys` and 16MB tmpfs on `/tmp`
2. Copies entire system (`/bin`, `/sbin`, `/etc`, `/lib`, `/usr`) to RAM
3. Executes `pivot_root` to switch to the RAM-based system
4. Unmounts the original floppy
5. Loads network modules (`8139too`)
6. Displays the welcome banner
7. Starts interactive shell

## Creating New Floppy Images

### Floppy 1 (FAT12 for SYSLINUX)

```bash
# Create empty image
dd if=/dev/zero of=floppy1-boot.img bs=1024 count=1440

# Format as FAT12
mkfs.vfat floppy1-boot.img

# Install SYSLINUX
syslinux floppy1-boot.img

# Mount and copy files
sudo mount -o loop floppy1-boot.img /mnt/floppy1
sudo cp bzImage /mnt/floppy1/
sudo cp syslinux.cfg /mnt/floppy1/
sudo umount /mnt/floppy1
```

### Floppy 2 (ext2 for rootfs)

```bash
# Create empty image
dd if=/dev/zero of=floppy2-rootfs.img bs=1024 count=1440

# Format as ext2
mkfs.ext2 floppy2-rootfs.img

# Mount and copy filesystem
sudo mount -o loop floppy2-rootfs.img /mnt/floppy2
sudo rsync -av filesystem/ /mnt/floppy2/
sudo umount /mnt/floppy2
```

## Quick Commands

```bash
# Update kernel only
cd linux && make ARCH=x86 bzImage -j$(nproc) && \
sudo mount -o loop ../floppy1-boot.img /mnt/floppy1 && \
sudo cp arch/x86/boot/bzImage /mnt/floppy1/ && \
sudo umount /mnt/floppy1

# Update filesystem only
sudo mount -o loop floppy2-rootfs.img /mnt/floppy2 && \
sudo rsync -av filesystem/ /mnt/floppy2/ && \
sudo umount /mnt/floppy2

# Update kernel + modules + filesystem
cd linux && \
make ARCH=x86 bzImage -j$(nproc) && \
find . -name "*.ko" -delete && \
make ARCH=x86 modules -j$(nproc) && \
KVER=$(make kernelrelease) && \
sudo mkdir -p ../filesystem/lib/modules/$KVER && \
sudo rm -fr ../filesystem/lib/modules/$KVER/* && \
find . -name "*.ko" | xargs -I {} sudo cp {} ../filesystem/lib/modules/$KVER && \
sudo depmod -b ../filesystem -a $KVER && \
sudo mount -o loop ../floppy1-boot.img /mnt/floppy1 && \
sudo cp arch/x86/boot/bzImage /mnt/floppy1/ && \
sudo umount /mnt/floppy1 && \
sudo mount -o loop ../floppy2-rootfs.img /mnt/floppy2 && \
sudo rsync -av ../filesystem/ /mnt/floppy2/ && \
sudo umount /mnt/floppy2
```

## Differences from Original Floppinux

| Feature | Floppinux | Ginebra Linux |
|---------|-----------|---------------|
| Floppies | 1 | 2 |
| Boot filesystem | FAT12 + initramfs | FAT12 (kernel only) |
| Root filesystem | cpio.xz in RAM | ext2 on second floppy |
| Modules | No module support | Extensible |
| Network | No network | RTL8139 with modules |

## Precompiled Binaries

Static binaries compiled for i486 are available for download. Once Ginebra Linux is running with network access, you can download and run them directly.

### Available Binaries

| Binary | Size | Description |
|--------|------|-------------|
| [bash](./repo/bash) | ~1080KB | GNU Bash with readline and history |
| [links](./repo/links) | ~1380KB | Text-based web browser (no SSL) |



### Installing Binaries from Ginebra Linux

```bash
# Configure network (if not already done)
ifconfig eth0 10.0.2.15 netmask 255.255.255.0
route add default gw 10.0.2.2

# Download bash
wget http://your-server/binaries/bash
chmod +x bash
./bash

# Download links
wget http://your-server/binaries/links
chmod +x links
./links http://example.com
```

### Quick Install Script

```bash
# Download and install to /bin
cd /tmp
wget http://your-server/binaries/bash
wget http://your-server/binaries/links
chmod +x bash links
mv bash links /bin/

# Now you can use them directly
bash
links http://example.com
```

### Using Bash as Default Shell

To use bash instead of ash (BusyBox shell), edit `/etc/inittab`:

```bash
# Change this line:
::askfirst:/bin/sh
# To:
::askfirst:/bin/bash
```

Or set environment variables for history support:

```bash
export HOME=/home
export HISTFILE=/home/.bash_history
export HISTSIZE=100
```

## Roadmap: Bali Package Manager

**Bali** (named after my other cat) will be a minimal package manager for Ginebra Linux:

- Download and install static binaries over HTTP
- Simple package index (text file with URLs and checksums)
- Minimal footprint suitable for floppy-based systems

```bash
# Future usage (planned)
bali update                  # Fetch package index
bali search vim              # Search for packages
bali install vim             # Download and install
bali list                    # List installed packages
```

## Demo
[Watch Demo](./demo.mp4)

## Credits

- Original project: [Floppinux](https://github.com/w84death/floppinux) by Krzysztof Krystian Jankowski
- Fork: Ginebra Linux (in honor of Ginebra the cat)

## License

CC0 1.0 Universal - Public Domain
