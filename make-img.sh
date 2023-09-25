#! /bin/bash

if [[ "$#" -ne 1 ]]; then
    echo "Usage: ./make-image.sh some_root.tar.xz"
    exit 2
fi

# create temp directory for mounting
TMP_DIR=$(mktemp -d --tmpdir=.)

# temp file for modifying /etc/passwd in the image
TMP_FILE=$(mktemp --tmpdir=.)

IMG_NAME=${2-make-image-output.img}

qemu-img create -f raw ${IMG_NAME} 20g
mkfs.ext4 ${IMG_NAME}
sudo mount ${IMG_NAME} ${TMP_DIR}
sudo tar xvf $1 -C ${TMP_DIR}
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
