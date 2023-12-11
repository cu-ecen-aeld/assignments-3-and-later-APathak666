#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.

set -e
set -u

OUTDIR=/tmp/aesd-autograder
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-linux-gnu-

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi

# mkdir -p ${OUTDIR}

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # TODO: Add your kernel build steps here
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} mrproper
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} defconfig
    # cp ${FINDER_APP_DIR}/fix_multiple_def_yyloc.patch .
    # git apply fix_multiple_def_yyloc.patch
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} all
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} modules
    make ARCH=arm64 CROSS_COMPILE=${CROSS_COMPILE} dtbs
    cd ..   
fi

echo "Adding the Image in outdir"
cp linux-stable/arch/${ARCH}/boot/Image $OUTDIR

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
	echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    sudo rm  -rf ${OUTDIR}/rootfs
fi

# TODO: Create necessary base directories
mkdir "$OUTDIR"/rootfs
cd "$OUTDIR"/rootfs
mkdir -p bin dev etc home lib lib64 proc sbin sys tmp usr var
mkdir -p usr/bin usr/lib usr/sbin
mkdir -p var/log

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # TODO:  Configure busybox
    make distclean
    make defconfig
    sed 's/^.*CONFIG_STATIC.*$/CONFIG_STATIC=y/g' -i .config
else
    cd busybox
fi

# TODO: Make and install busybox
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE}
make ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} CONFIG_PREFIX=${OUTDIR}/rootfs install

# echo "Library dependencies"
# ${CROSS_COMPILE}readelf -a /bin/busybox | grep "program interpreter"
# ${CROSS_COMPILE}readelf -a /bin/busybox | grep "Shared library"

# TODO: Add library dependencies to rootfs
cp /usr/aarch64-linux-gnu/lib/ld-linux-aarch64.so.1 ../rootfs/lib64
cp /usr/aarch64-linux-gnu/lib/libm.so.6 ../rootfs/lib64
cp /usr/aarch64-linux-gnu/lib/libresolv.so.2 ../rootfs/lib64
cp /usr/aarch64-linux-gnu/lib/libc.so.6 ../rootfs/lib64

# TODO: Make device nodes
cd ../rootfs
sudo mknod -m 666 dev/null c 1 3
sudo mknod -m 666 dev/console c 5 1
sudo mknod -m 666 dev/ram b 1 0

# TODO: Clean and build the writer utility
cd ${FINDER_APP_DIR}
echo ${FINDER_APP_DIR}
make clean
make target CROSS_COMPILE=${CROSS_COMPILE}

# TODO: Copy the finder related scripts and executables to the /home directory
# on the target rootfs
cd "$OUTDIR/rootfs/home"
mkdir conf
cp ${FINDER_APP_DIR}/autorun-qemu.sh .
cp ${FINDER_APP_DIR}/finder.sh .
cp ${FINDER_APP_DIR}/finder-test.sh .
cp ${FINDER_APP_DIR}/../conf/assignment.txt conf/
cp ${FINDER_APP_DIR}/../conf/username.txt conf/
cp ${FINDER_APP_DIR}/writer.sh .

# TODO: Chown the root directory
sudo chown -R root:root "$OUTDIR/rootfs/home"

# TODO: Create initramfs.cpio.gz
cd "$OUTDIR/rootfs"
find . | cpio -H newc -ov --owner root:root | gzip -f > ../initramfs.cpio.gz
