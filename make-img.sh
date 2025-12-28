#! /bin/bash

# exit immediately if any command fails
set -e
IMG_NAME="make-image-output.img"
IMG_SIZE=60

usage() {
    U=""
    if [[ -n "$1" ]]; then
        U="${U}$1\n\n"
    fi
    U="${U}Usage: $0 [options]\n\n"
    U="${U}Options:\n"
    U="$U    -s | --size <GB>:       Size of disk image in GBs (default: ${IMG_SIZE}g)\n"
    U="$U    -f | --fs <file>:       rootfs tar.xz\n"
    U="$U    -o | --output <file>:   output file name (default: ${IMG_NAME})\n"
    echo -e "$U" >&2
}

while :
do
    case "$1" in
      -s | --size)
        IMG_SIZE="$2"
        shift 2
        ;;
      -f | --fs)
        FS_TAR="$2"
        shift 2
        ;;
      -o | --output)
        IMG_NAME="$2"
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

if [[ -z "$FS_TAR" ]]; then
    echo "Please supply rootfs tar.xz" >&2
    exit 1
fi

# create temp directory for mounting
TMP_DIR=$(mktemp -d --tmpdir=.)

# temp file for modifying /etc/passwd in the image
TMP_FILE=$(mktemp --tmpdir=.)

truncate -s ${IMG_SIZE}g ${IMG_NAME}
mkfs.ext4 ${IMG_NAME}
sudo mount ${IMG_NAME} ${TMP_DIR}
sudo tar xvf ${FS_TAR} -C ${TMP_DIR}
sudo sync
sudo touch ${TMP_DIR}/etc/cloud/cloud-init.disabled
# copy /etc/passwd to TMP_FILE but without the first line
sudo /bin/bash -c "tail -n +2 ${TMP_DIR}/etc/passwd > ${TMP_FILE}"
# remove the original /etc/passwd
sudo rm ${TMP_DIR}/etc/passwd
# add the first line (no root password) to TMP_FILE
sudo /bin/bash -c "echo root::0:0:root:/root:/bin/bash > ${TMP_DIR}/etc/passwd"
# copy the TMP_FILE to create the new /etc/passwd
sudo /bin/bash -c "cat ${TMP_FILE} >> ${TMP_DIR}/etc/passwd"
sudo sync
sudo umount ${TMP_DIR}

# remove the temp file
rm ${TMP_FILE}
# remove the temp directory
rm -rf ${TMP_DIR}
