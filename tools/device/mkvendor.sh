#!/bin/bash

function usage
{
    echo Usage:
    echo "  $(basename $0) manufacturer device boot.img"
    echo "  The boot.img argument is the extracted recovery or boot image."
    echo
    echo Example:
    echo "  $(basename $0) ~/Downloads/recovery-passion.img motorola sholes"
    exit 0
}

MANUFACTURER=$1
DEVICE=$2
BOOTIMAGE=$3

UNPACKBOOTIMG=$(which unpackbootimg)

if [ -z "$MANUFACTURER" ]
then
    usage
fi

if [ -z "$DEVICE" ]
then
    usage
fi

if [ -z "$BOOTIMAGE" ]
then
    usage
fi

if [ -z "$UNPACKBOOTIMG" ]
then
    echo unpackbootimg not found. Is your android build environment set up and have the host tools been built?
    exit 0
fi

BOOTIMAGEFILE=$(basename $BOOTIMAGE)

ANDROID_TOP=$(dirname $0)/../../../
pushd $ANDROID_TOP > /dev/null
ANDROID_TOP=$(pwd)
popd > /dev/null

TEMPLATE_DIR=$(dirname $0)
pushd $TEMPLATE_DIR > /dev/null
TEMPLATE_DIR=$(pwd)
popd > /dev/null

DEVICE_DIR=$ANDROID_TOP/device/$MANUFACTURER/$DEVICE
echo Output will be in $DEVICE_DIR
mkdir -p $DEVICE_DIR

TMPDIR=/tmp/bootimg
rm -rf $TMPDIR
mkdir -p $TMPDIR
cp $BOOTIMAGE $TMPDIR
pushd $TMPDIR > /dev/null
unpackbootimg -i $BOOTIMAGEFILE > /dev/null
BASE=$(cat $TMPDIR/$BOOTIMAGEFILE-base)
CMDLINE=$(cat $TMPDIR/$BOOTIMAGEFILE-cmdline)
PAGESIZE=$(cat $TMPDIR/$BOOTIMAGEFILE-pagesize)
export SEDCMD=s/__CMDLINE__/$CMDLINE/g
echo $SEDCMD > $TMPDIR/sedcommand
cp $TMPDIR/$BOOTIMAGEFILE-zImage $DEVICE_DIR/kernel
popd > /dev/null

for file in $(find $TEMPLATE_DIR -name '*.template')
do
    OUTPUT_FILE=$DEVICE_DIR/$(basename $(echo $file | sed s/\\.template//g))
    cat $file | sed s/__DEVICE__/$DEVICE/g | sed s/__MANUFACTURER__/$MANUFACTURER/g | sed -f $TMPDIR/sedcommand | sed s/__BASE__/$BASE/g | sed s/__PAGE_SIZE__/$PAGESIZE/g > $OUTPUT_FILE
done

mv $DEVICE_DIR/device.mk $DEVICE_DIR/device_$DEVICE.mk

echo Done!
echo Use the following command to set up your build environment:
echo '  'lunch full_$DEVICE-eng
echo And use the follwowing command to build a recovery:
echo '  '. build/tools/device/makerecoveries.sh full_$DEVICE-eng