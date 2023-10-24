# Linux Kernel Dev Environment

## Docker (Optional)

<https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository>

```bash
docker network create --driver bridge common
docker run -v host:container --priviledged --network common -it ubuntu bash
```

## Foundation

```bash
apt update
apt upgrade
# general
apt install sudo iputils-ping iproute2 git make wget zip libglib2.0-dev libpixman-1-dev
# Linux kernel compile
apt install pkg-config bc flex bison libssl-dev build-essential
# Linux kernel menuconfig
apt install libncurses-dev
# QEMU build
apt install ninja-build cmake
# QEMU shared dir
apt install libcap-ng-dev libattr1-dev
# VM debug
apt install telnet
```

## QEMU

```bash
git clone --depth 1 --branch v8.0.0 https://gitlab.com/qemu-project/qemu.git
# or
git clone https://gitlab.com/qemu-project/qemu.git
cd qemu/
git checkout tags/v8.0.0
./configure --target-list=aarch64-softmmu --disable-werror --enable-virtfs
make -j`nproc`
sudo make install
```

## Toolchain

```bash
# gcc
apt install gcc-aarch64-linux-gnu
# llvm
git clone --depth 1 --branch llvmorg-16.0.0 https://github.com/llvm/llvm-project.git
cd llvm-project/
# I already have an older lld installed so I use -DLLVM_USE_LINKER, dont add if you dont have lld
cmake -S llvm -B build -G Ninja -DLLVM_ENABLE_PROJECTS="clang;lld" -DCMAKE_BUILD_TYPE=Release
 -DLLVM_USE_LINKER=lld
# this took an hour on my 8 CPU (11th gen Intel) laptop
cmake --build build
sudo cmake --build build --target install
```

## Linux Kernel

```bash
git clone --depth 1 --branch v6.0 https://github.com/torvalds/linux.git
# or
wget https://mirrors.edge.kernel.org/pub/linux/kernel/v6.x/linux-6.0.tar.xz
tar xvf linux-6.0.tar.xz
scripts/config -e SQUASHFS_XZ
# gcc
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j`nproc` Image
# llvm
make LLVM=1 ARCH=arm64 -j`nproc` Image
```

## Root Filesystem

```bash
wget https://cloud-images.ubuntu.com/releases/jammy/release/ubuntu-22.04-server-cloudimg-arm64-root.tar.xz
./make-img.sh --help
```

## In VM

```bash
# network
dhclient
# mount shared directory
mount -t 9p -o trans=virtio [mount tag] [mount point]
# configure ssh
dpkg-reconfigure openssh-server
# then do PermitRootLogin yes in /etc/ssh/sshd_config
# and copy public key to .ssh/authorized_keys (mod 600 and owner must be root)

# remove snap
# 1. see snap installed
snap list
# 2. remove packages
snap remove p1 p2...
systemctl stop snapd
apt remove --purge --assume-yes snapd gnome-software-plugin-snap
rm -rf ~/snap/
rm -rf /var/cache/snapd/
```
