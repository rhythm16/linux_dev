#! /bin/bash

# exit immediately if any command fails
set -e

usage() {
    U=""
    if [[ -n "$1" ]]; then
        U="${U}$1\n\n"
    fi
    U="${U}Usage: $0 [options]\n\n"
    U="${U}Options:\n"
    U="$U    -i | --image <img>:     disk image\n"
    U="$U    -f | --file <file>:     file to copy into the disk image\n"
    echo -e "$U" >&2
}

while :
do
    case "$1" in
      -i | --image)
        IMAGE="$2"
        shift 2
        ;;
      -f | --file)
        FILE="$2"
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

if [[ -z "$IMAGE" ]]; then
    echo "Please supply disk image" >&2
    usage ""
    exit 1
fi

if [[ -z "$FILE" ]]; then
    echo "Please supply file to copy into the disk image" >&2
    usage ""
    exit 1
fi

# create temp directory for mounting
TMP_DIR=$(mktemp -d --tmpdir=.)

sudo mount ${IMAGE} ${TMP_DIR}
sudo cp -r ${FILE} ${TMP_DIR}/root
sudo sync
sudo umount ${TMP_DIR}

# remove the temp directory
rm -rf ${TMP_DIR}
