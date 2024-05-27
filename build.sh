#!/bin/bash


# Variables
DIR=`readlink -f .`;
PARENT_DIR=`readlink -f ${DIR}/..`;

DEFCONFIG_NAME=wirus_defconfig
CHIPSET_NAME=kona
VARIANT=r8q
ARCH=arm64
VERSION=Nethunter_WirusMOD_${VARIANT}_v4.0.1
BOARD_KERNEL_CMDLINE="console=tty1 droidian.lvm.prefer androidboot.hardware=qcom androidboot.memcg=1 lpm_levels.sleep_disabled=1 video=vfb:640x400,bpp=32,memsize=3072000 msm_rtb.filter=0x237 service_locator.enable=1 androidboot.usbcontroller=a600000.dwc3 swiotlb=2048 printk.devkmsg=on firmware_class.path=/vendor/firmware_mnt/image"
MKBOOTIMG_AFLAG="--cmdline \"${BOARD_KERNEL_CMDLINE}\" \
				--base 0x00000000 --pagesize ${BOARD_KERNEL_PAGESIZE} \
				--os_version ${PLATFORM_VERSION} --os_patch_level ${PLATFORM_SECURITY_PATCH} \
				--ramdisk_offset 0x02000000 --tags_offset 0x01E00000 \
				--dtb dtb.img --header_version 2 \
				--board SRPSH29C000"
#*** TARGET CONFIG END ***#

BUILD_CROSS_COMPILE=$DIR/toolchain/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-
KERNEL_LLVM_BIN=$DIR/toolchain/llvm-arm-toolchain-ship/10.0/bin/clang
CLANG_TRIPLE=aarch64-linux-gnu-
KERNEL_MAKE_ENV="DTC_EXT=$(pwd)/tools/dtc CONFIG_BUILD_ARM64_DT_OVERLAY=y LOCALVERSION=-${VERSION}"

DTS_DIR=$PARENT_DIR/out/arch/$ARCH/boot/dts

#Compile kernel:
[ ! -d "$PARENT_DIR/out" ] && mkdir $PARENT_DIR/out
  make -j$(nproc) -C $(pwd) O=$PARENT_DIR/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE CFP_CC=$KERNEL_LLVM_BIN $DEFCONFIG_NAME
  make -j$(nproc) -C $(pwd) O=$PARENT_DIR/out $KERNEL_MAKE_ENV ARCH=arm64 CROSS_COMPILE=$BUILD_CROSS_COMPILE REAL_CC=$KERNEL_LLVM_BIN CLANG_TRIPLE=$CLANG_TRIPLE CFP_CC=$KERNEL_LLVM_BIN

#Generate boot.img:
 [ -e $PARENT_DIR/out/arch/arm64/boot/Image.gz ] && cp $PARENT_DIR/out/arch/arm64/boot/Image.gz $PARENT_DIR/out/Image.gz
  if [ -e $PARENT_DIR/out/arch/arm64/boot/Image.gz-dtb ]; then
    cp $PARENT_DIR/out/arch/arm64/boot/Image.gz-dtb $PARENT_DIR/out/Image.gz-dtb

    DTBO_FILES=$(find ${DTS_DIR}/samsung/ -name ${CHIPSET_NAME}-sec-${VARIANT}-*-r*.dtbo)
    cat ${DTS_DIR}/vendor/qcom/*.dtb > $PARENT_DIR/out/dtb.img
    $(pwd)/tools/mkdtimg create $PARENT_DIR/out/dtbo.img --page_size=4096 ${DTBO_FILES}
fi

#Create flashable zip:
  if [ ! -d $PARENT_DIR/AnyKernel3 ]; then
    echo "Copy AnyKernel3 to Parent DIR - Flashable Zip Template"
    cp -rf ${DIR}/AnyKernel3 $PARENT_DIR/AnyKernel3
  fi

  [ -e $PARENT_DIR/${VERSION}.zip ] && rm $PARENT_DIR/${VERSION}.zip
  if [ -e $PARENT_DIR/out/arch/arm64/boot/Image.gz-dtb ]; then
    cp $PARENT_DIR/out/arch/arm64/boot/Image.gz-dtb $PARENT_DIR/AnyKernel3/zImage
  elif [ -e $PARENT_DIR/out/arch/arm64/boot/Image.gz ]; then
    cp $PARENT_DIR/out/arch/arm64/boot/Image.gz $PARENT_DIR/AnyKernel3/zImage
  else
    echo "Error"
  fi
  cd $PARENT_DIR/AnyKernel3

  mkdir -p $PARENT_DIR/build/$VARIANT/modules
  zip -r9 $PARENT_DIR/build/$VARIANT/${VERSION}.zip * -x .git README.md *placeholder
  cd $DIR

find $PARENT_DIR/out/ -name '*.ko'  -not -path "$PARENT_DIR/build/*" -exec cp --parents -f '{}' $PARENT_DIR/build/$VARIANT/modules  \;
mv -f $PARENT_DIR/build/$VARIANT/modules/home/svirusx/out/* $PARENT_DIR/build/$VARIANT/modules





