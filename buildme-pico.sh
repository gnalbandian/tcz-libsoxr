#!/bin/sh

SOXR=soxr
SOXRVERSION=0.1.1
SRC=$SOXR-$SOXRVERSION-Source
LOG=$PWD/config.log
OUTPUT=$PWD/$SOXR-build
TCZ=lib${SOXR}.tcz

# Build requires these extra packages in addition to the raspbian 7.6 build tools
# sudo apt-get install squashfs-tools cmake bsdtar

## Start
echo "Most log mesages sent to $LOG... only 'errors' displayed here"
date > $LOG

# Clean up
if [ -d $OUTPUT ]; then
	rm -rf $OUTPUT >> $LOG
fi

if [ -d $SRC ]; then
	rm -rf $SRC >> $LOG
fi

## Build
echo "Untarring..."
bsdtar -xf $SRC.tar.xz >> $LOG

cd $SRC >> $LOG

echo "Applying patches"
patch -p1 -i ../soxr-fixes.patch >> $LOG

echo "Running cmake"
build=Release
rm -f CMakeCache.txt >> $LOG
mkdir $build >> $LOG
cd $build >> $LOG
cmake -DWITH_OPENMP=OFF .. >> $LOG

echo "Running make"
make >> $LOG

echo "Building tcz"
cd ../.. >> $LOG

if [ -f $TCZ ]; then
	rm $TCZ >> $LOG
fi

mkdir -p $OUTPUT/usr/lib >> $LOG

# Not needed if OPENMP disabled in cmake
# cp -p /usr/lib/arm-linux-gnueabihf/libgomp.so.1.0.0 $OUTPUT/usr/lib/libgomp.so.1 >> $LOG

# Not needed twice, included in libfaad.tcz. TODO create a separate libcofi.tcz
# cp -p /usr/lib/arm-linux-gnueabihf/libcofi_rpi.so $OUTPUT/usr/lib/ >> $LOG

cp -p $SRC/Release/src/libsoxr.so.0.1.0 $OUTPUT/usr/lib/libsoxr.so.0 >> $LOG
strip $OUTPUT/usr/lib/libsoxr.so.0 >> $LOG

mksquashfs $OUTPUT $TCZ -all-root >> $LOG
md5sum $TCZ > ${TCZ}.md5.txt

echo "$TCZ contains"
unsquashfs -ll $TCZ
