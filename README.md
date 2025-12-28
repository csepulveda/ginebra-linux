# Ginebra Linux

```
       /\_____/\
      /  o   o  \      Una distribucion Linux minimalista
     ( ==  ^  == )     que cabe en dos disquetes de 1.44MB
      )         (
     (           )     ~ meow ~
    ( (  )   (  ) )
   (__(__)___(__)__)
```

**Ginebra Linux** es un fork de [Floppinux](https://github.com/w84death/floppinux) que extiende el concepto original usando **dos disquetes**:

- **Floppy 1 (boot)**: Contiene el kernel (`bzImage`) y SYSLINUX
- **Floppy 2 (rootfs)**: Sistema de archivos ext2 con BusyBox, modulos del kernel y soporte de red

El sistema arranca desde el primer disquete, te da 30 segundos para cambiar al segundo, y luego copia todo a RAM para correr completamente desde memoria.

## Caracteristicas

- Kernel Linux 6.14.x compilado para i486
- BusyBox 1.36.1 (compilacion estatica con musl)
- Soporte de red (driver RTL8139)
- Modulos del kernel cargables
- Sistema corre 100% desde RAM despues del boot
- Ideal para hardware retro o maquinas virtuales

## Requisitos

- Ubuntu Linux (para compilacion)
- ~3GB de espacio en disco
- Paquetes: `build-essential`, `flex`, `bison`, `libncurses-dev`, `libelf-dev`, `libssl-dev`, `bc`, `syslinux`, `mtools`

```bash
sudo apt update
sudo apt install build-essential flex bison libncurses-dev libelf-dev libssl-dev bc syslinux mtools dosfstools e2fsprogs
```

## Estructura del Proyecto

```
ginebra-linux/
├── linux/                    # Codigo fuente del kernel
├── busybox-1_36_1/          # Codigo fuente de BusyBox
├── filesystem/              # Sistema de archivos raiz
│   ├── bin/                 # Comandos (enlaces a busybox)
│   ├── sbin/                # Comandos del sistema
│   ├── etc/init.d/rc        # Script de arranque
│   ├── lib/modules/         # Modulos del kernel
│   └── welcome              # Banner ASCII
├── i486-linux-musl-cross/   # Toolchain de compilacion cruzada
├── bzImage                  # Kernel compilado
├── floppy1-boot.img         # Imagen del disquete de boot
├── floppy2-rootfs.img       # Imagen del disquete rootfs
└── syslinux.cfg             # Configuracion del bootloader
```

## Compilacion

### 1. Descargar Toolchain

```bash
wget https://musl.cc/i486-linux-musl-cross.tgz
tar xzf i486-linux-musl-cross.tgz
export PATH="$PWD/i486-linux-musl-cross/bin:$PATH"
```

### 2. Compilar el Kernel

#### 2.1 Descargar el kernel

```bash
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.14.11.tar.xz
tar xf linux-6.14.11.tar.xz
mv linux-6.14.11 linux
cd linux
```

#### 2.2 Configuracion desde tinyconfig

Partimos de `tinyconfig` (la configuracion mas minima) y habilitamos solo lo necesario:

```bash
cd linux

# Partir de tinyconfig
make ARCH=x86 tinyconfig

# ============================================
# ARQUITECTURA Y CPU (i486)
# ============================================
scripts/config --enable CONFIG_M486
scripts/config --disable CONFIG_64BIT

# ============================================
# COMPRESION DEL KERNEL (XZ para minimo tamano)
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
# OPTIMIZACION PARA TAMANO
# ============================================
scripts/config --disable CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE
scripts/config --enable CONFIG_CC_OPTIMIZE_FOR_SIZE
scripts/config --enable CONFIG_SLUB_TINY

# ============================================
# MODULOS DEL KERNEL
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
# SISTEMAS DE ARCHIVOS
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
# RED (NETWORKING)
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
# INPUT / TECLADO / CONSOLA
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
# FORMATOS EJECUTABLES
# ============================================
scripts/config --enable CONFIG_BINFMT_ELF
scripts/config --enable CONFIG_BINFMT_SCRIPT

# ============================================
# OPCIONES DE EXPERTO (necesarias para acceder a otras)
# ============================================
scripts/config --enable CONFIG_EXPERT
scripts/config --enable CONFIG_PRINTK
scripts/config --enable CONFIG_POSIX_TIMERS

# ============================================
# EEPROM (requerido por 8139too)
# ============================================
scripts/config --enable CONFIG_EEPROM_93CX6

# ============================================
# MISC
# ============================================
scripts/config --enable CONFIG_MICROCODE
scripts/config --set-val CONFIG_HZ 250
scripts/config --enable CONFIG_PERF_EVENTS

# ============================================
# DESHABILITAR FUNCIONES NO NECESARIAS
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

# Resolver dependencias automaticamente
make ARCH=x86 olddefconfig
```

#### 2.3 Compilar kernel y modulos

```bash
# Compilar kernel
make ARCH=x86 bzImage -j$(nproc)

# Verificar tamano (debe ser menor a ~900KB)
du -ks arch/x86/boot/bzImage

# Limpiar modulos viejos y recompilar
find . -name "*.ko" -delete
make ARCH=x86 modules -j$(nproc)
```

#### 2.4 Configuracion interactiva (opcional)

Si necesitas ajustar opciones manualmente:

```bash
make ARCH=x86 menuconfig
```

### 3. Compilar BusyBox

```bash
cd busybox-1_36_1

# Configurar (usa config existente o menuconfig)
make ARCH=x86 olddefconfig
# make ARCH=x86 menuconfig

# Compilar e instalar
make ARCH=x86 -j$(nproc)
make ARCH=x86 install

# Copiar al filesystem
sudo rsync -av _install/ ../filesystem/
```

### 4. Crear Puntos de Montaje

```bash
sudo mkdir -p /mnt/floppy1 /mnt/floppy2
```

### 5. Actualizar Disquete 1 (Boot)

```bash
cd linux

# Montar imagen de boot
sudo mount -o loop ../floppy1-boot.img /mnt/floppy1

# Copiar kernel
sudo cp arch/x86/boot/bzImage /mnt/floppy1/bzImage

# Verificar espacio
df -k /mnt/floppy1

# Desmontar
sudo umount /mnt/floppy1
```

### 6. Actualizar Disquete 2 (RootFS)

```bash
cd linux

# Obtener version del kernel
KVER=$(make kernelrelease)
echo "Kernel version: $KVER"

# Preparar directorio de modulos
sudo mkdir -p ../filesystem/lib/modules/$KVER
sudo rm -fr ../filesystem/lib/modules/$KVER/*

# Copiar modulos compilados
find . -name "*.ko" | xargs -I {} sudo cp {} ../filesystem/lib/modules/$KVER

# Generar dependencias de modulos
sudo depmod -b ../filesystem -a $KVER

# Verificar modulos instalados
sudo find ../filesystem/lib/modules/$KVER

# Montar imagen rootfs
sudo mount -o loop ../floppy2-rootfs.img /mnt/floppy2

# Sincronizar filesystem
sudo rsync -av ../filesystem/ /mnt/floppy2/

# Verificar espacio
df -k /mnt/floppy2

# Desmontar
sudo umount /mnt/floppy2
```

### 7. Editar Configuracion de SYSLINUX (Opcional)

```bash
# Montar disquete de boot
sudo mount -o loop floppy1-boot.img /mnt/floppy1

# Editar configuracion
sudo vim syslinux.cfg

# Copiar a disquete
sudo cp syslinux.cfg /mnt/floppy1/

# Desmontar
sudo umount /mnt/floppy1
```

## Configuracion de SYSLINUX

El archivo `syslinux.cfg` para sistema de dos disquetes:

```
DEFAULT ginebra
PROMPT 1
TIMEOUT 5

LABEL ginebra
SAY [ GINEBRA LINUX - 30 segundos para cambiar el disco ]
KERNEL bzImage
APPEND root=/dev/fd0 rootfstype=ext2 rootdelay=30 rw console=tty0 init=/etc/init.d/rc tsc=unstable
```

**Parametros importantes:**
- `root=/dev/fd0` - Usar disquetera como root
- `rootfstype=ext2` - Sistema de archivos ext2
- `rootdelay=30` - Esperar 30 segundos para cambiar disco
- `init=/etc/init.d/rc` - Script de inicio personalizado

## Probar con QEMU

```bash
# Con dos disquetes fisicos simulados
qemu-system-i386 -m 32 \
    -drive file=floppy1-boot.img,format=raw,if=floppy,index=0 \
    -drive file=floppy2-rootfs.img,format=raw,if=floppy,index=1 \
    -boot a

# Con red (RTL8139)
qemu-system-i386 -m 32 \
    -drive file=floppy1-boot.img,format=raw,if=floppy,index=0 \
    -drive file=floppy2-rootfs.img,format=raw,if=floppy,index=1 \
    -boot a \
    -netdev user,id=net0 \
    -device rtl8139,netdev=net0
```

## Escribir a Disquetes Reales

```bash
# Disquete 1 (boot)
sudo dd if=floppy1-boot.img of=/dev/fd0 bs=1024

# Disquete 2 (rootfs)
sudo dd if=floppy2-rootfs.img of=/dev/fd0 bs=1024
```

## Script de Inicio (rc)

El script `/etc/init.d/rc` realiza:

1. Monta `/proc`, `/sys` y tmpfs de 16MB en `/tmp`
2. Copia todo el sistema (`/bin`, `/sbin`, `/etc`, `/lib`, `/usr`) a RAM
3. Ejecuta `pivot_root` para cambiar al sistema en RAM
4. Desmonta el disquete original
5. Carga modulos de red (`8139too`)
6. Muestra el banner de bienvenida
7. Inicia shell interactivo

## Crear Imagenes de Disquete Nuevas

### Disquete 1 (FAT12 para SYSLINUX)

```bash
# Crear imagen vacia
dd if=/dev/zero of=floppy1-boot.img bs=1024 count=1440

# Formatear como FAT12
mkfs.vfat floppy1-boot.img

# Instalar SYSLINUX
syslinux floppy1-boot.img

# Montar y copiar archivos
sudo mount -o loop floppy1-boot.img /mnt/floppy1
sudo cp bzImage /mnt/floppy1/
sudo cp syslinux.cfg /mnt/floppy1/
sudo umount /mnt/floppy1
```

### Disquete 2 (ext2 para rootfs)

```bash
# Crear imagen vacia
dd if=/dev/zero of=floppy2-rootfs.img bs=1024 count=1440

# Formatear como ext2
mkfs.ext2 floppy2-rootfs.img

# Montar y copiar filesystem
sudo mount -o loop floppy2-rootfs.img /mnt/floppy2
sudo rsync -av filesystem/ /mnt/floppy2/
sudo umount /mnt/floppy2
```

## Comandos Rapidos

```bash
# Actualizar solo el kernel
cd linux && make ARCH=x86 bzImage -j$(nproc) && \
sudo mount -o loop ../floppy1-boot.img /mnt/floppy1 && \
sudo cp arch/x86/boot/bzImage /mnt/floppy1/ && \
sudo umount /mnt/floppy1

# Actualizar solo el filesystem
sudo mount -o loop floppy2-rootfs.img /mnt/floppy2 && \
sudo rsync -av filesystem/ /mnt/floppy2/ && \
sudo umount /mnt/floppy2

# Actualizar kernel + modulos + filesystem
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

## Diferencias con Floppinux Original

| Caracteristica | Floppinux | Ginebra Linux |
|---------------|-----------|---------------|
| Disquetes | 1 | 2 |
| Boot filesystem | FAT12 + initramfs | FAT12 (solo kernel) |
| Root filesystem | cpio.xz en RAM | ext2 en segundo disquete |
| Modulos | Sin soporte a modulos | Extensibles |
| Red | Sin Red | RTL8139 con modulos |


## Demo
[Ver Demo](./demo.mp4)

## Creditos

- Proyecto original: [Floppinux](https://github.com/w84death/floppinux) por Krzysztof Krystian Jankowski
- Fork: Ginebra Linux (en honor a la gata Ginebra)

## Licencia

CC0 1.0 Universal - Dominio Publico
