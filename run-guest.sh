#!/bin/bash

CONSOLE=mon:stdio
SMP=2
MEMSIZE=$((4096))
KERNEL="Image"
FS=cloud.img
CMDLINE="earlycon=pl011,0x09000000" #log_buf_len=64M " #kvm-arm.mode=protected" # memblock=debug"
DTB=""
UNDERSCORE_S=""
SHARED_OPT=""
GUEST_32=""

usage() {
    U=""
    if [[ -n "$1" ]]; then
        U="${U}$1\n\n"
    fi
    U="${U}Usage: $0 [options]\n\n"
    U="${U}Options:\n"
    U="$U    -c | --CPU <nr>:       Number of cores (default ${SMP})\n"
    U="$U    -m | --mem <MB>:       Memory size (default ${MEMSIZE})\n"
    U="$U    -k | --kernel <Image>: Use kernel image (default ${KERNEL})\n"
    U="$U    -s | --serial <file>:  Output console to <file>\n"
    U="$U    -i | --image <image>:  Use <image> as block device (default $FS)\n"
    U="$U    -a | --append <snip>:  Add <snip> to the kernel cmdline\n"
    U="$U    -w | --guest_32:       Run guest in AArch32 state\n"
    U="$U    --dtb <file>           Use the supplied DTB instead of the auto-generated one\n"
    U="$U    -S                     Stop on startup, wait for GDB\n"
    U="$U    -x | --shared_dir:     Shared directory path\n"
    U="$U    -h | --help:           Show this output\n"
    U="${U}\n"
    echo -e "$U" >&2
}

while :
do
    case "$1" in
      -c | --cpu)
        SMP="$2"
        shift 2
        ;;
      -m | --mem)
        MEMSIZE="$2"
        shift 2
        ;;
      -k | --kernel)
        KERNEL="$2"
        shift 2
        ;;
      -s | --serial)
        CONSOLE="file:$2"
        shift 2
        ;;
      -i | --image)
        FS="$2"
        shift 2
        ;;
      -a | --append)
        CMDLINE="$2"
        shift 2
        ;;
      -w | --guest_32)
        GUEST_32=",aarch64=off"
        shift 1
        ;;
      --dtb)
        DTB="-dtb $2"
        shift 2
        ;;
      -S)
        UNDERSCORE_S="-S"
        shift 1
        ;;
      -x | --shared_dir)
        SHARED_DIR="$2"
        SHARED_OPT="-virtfs local,path=${SHARED_DIR},mount_tag=shared,security_model=passthrough"
        shift 2
        ;;
      -h | --help)
        usage ""
        exit 1
        ;;
      --) # End of all options
        shift
        break
        ;;
      -*) # Unknown option
        echo "Error: Unknown option: $1" >&2
        exit 1
        ;;
      *)
        break
        ;;
    esac
done

if [[ -z "$KERNEL" ]]; then
    echo "You must supply a guest kernel" >&2
    exit 1
fi

qemu-system-aarch64 -nographic -machine virt,gic-version=3 -m ${MEMSIZE} -cpu host${GUEST_32} \
    -smp ${SMP} -enable-kvm \
    -kernel ${KERNEL} ${DTB} \
    -drive if=none,file=$FS,id=vda,cache=none,format=raw \
    -device virtio-blk-pci,drive=vda \
    -display none \
    -serial $CONSOLE \
    -append "console=ttyAMA0 root=/dev/vda rw $CMDLINE" \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=net0,mac=de:ad:be:ef:41:49 \
    ${SHARED_OPT} \
    -gdb tcp::12345 \
    -monitor telnet:localhost:23456,server,nowait \
    ${UNDERSCORE_S}
