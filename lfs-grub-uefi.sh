#!/bin/bash
# LFS 11.0-systemd Build Script
# Builds GRUB EFI
# by Luís Mendes and CaffeJappa :)
# 05/Jan/2022

package_name=""
package_ext=""

begin() {
	package_name=$1
	package_ext=$2

	echo "[lfs-scripts] Starting build of $package_name at $(date)"

	tar xf $package_name.$package_ext
	cd $package_name
}

finish() {
	echo "[lfs-scripts] Finishing build of $package_name at $(date)"

	cd /sources-grub
	rm -rf $package_name
}

mkdir /sources-grub
cp /sources/grub-2.06.tar.xz /sources-grub
cd /sources-grub

# Popt-1.18

begin popt-1.18 tar.gz
./configure --prefix=/usr --disable-static &&
make -j4
make install
finish

# efivar-37

begin efivar-37 tar.bz2
patch -Np1 -i ../efivar-37-gcc_9-1.patch
make -j4 CFLAGS="-O2 -Wno-stringop-truncation"
make install LIBDIR=/usr/lib
finish

# efibootmgr-17

begin efibootmgr-17 tar.gz
sed -e '/extern int efi_set_verbose/d' -i src/efibootmgr.c
make -j4 EFIDIR=LFS EFI_LOADER=grubx64.efi
make install EFIDIR=LFS
finish

# which-2.21
begin which-2.21 tar.gz
./configure --prefix=/usr &&
make -j4
make install
finish

# libpng-1.6.37

begin libpng-1.6.37 tar.xz
./configure --prefix=/usr --disable-static &&
make -j4
make install &&
mkdir -v /usr/share/doc/libpng-1.6.37 &&
cp -v README libpng-manual.txt /usr/share/doc/libpng-1.6.37
finish

# FreeType-2.11.0

begin freetype-2.11.0 tar.xz
sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg &&

sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
    -i include/freetype/config/ftoption.h  &&

./configure --prefix=/usr --enable-freetype-config --disable-static &&
make -j4
make install
finish

# GRUB-2.06

begin grub-2.06 tar.xz
mkdir -pv /usr/share/fonts/unifont &&
gunzip -c ../unifont-13.0.06.pcf.gz > /usr/share/fonts/unifont/unifont.pcf
unset {C,CPP,CXX,LD}FLAGS
./configure --prefix=/usr        \
            --sysconfdir=/etc    \
            --disable-efiemu     \
            --enable-grub-mkfont \
            --with-platform=efi  \
            --disable-werror     &&
make -j4
make install &&
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
finish

# Install GRUB
mkdir -p /boot/efi/LFS
grub-install --efi-directory=/boot --bootloader-id=LFS
grub-mkconfig -o /boot/grub/grub.cfg
