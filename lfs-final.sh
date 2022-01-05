#!/bin/bash
# LFS 11.0 Build Script
# Final steps to configure the system
# by Luís Mendes :)
# 13/Sep/2021

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

	cd /sources
	rm -rf $package_name
}

cd /sources

find /usr/lib /usr/libexec -name \*.la -delete
find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf

# 9.2. Network Configuration
echo [NETWORK] Making Static Configuration
cat > /etc/systemd/network/10-eth-static.network << "EOF"
[Match]
Name=enp2s0

[Network]
Address=192.168.0.2/24
Gateway=192.168.0.1
EOF
echo [NETWORK] Making DHCP Configuration
cat > /etc/systemd/network/10-eth-dhcp.network << "EOF"
[Match]
Name=enp2s0

[Network]
DHCP=ipv4

[DHCP]
UseDomains=true
EOF

# 9.2.2. Creating the /etc/resolv.conf File
cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf

nameserver 8.8.8.8
nameserver 8.8.4.4

# End /etc/resolv.conf
EOF

# 9.2.3. Configuring the system hostname
echo "lfs" > /etc/hostname

# 9.2.4. Customizing the /etc/hosts File
cat > /etc/hosts << "EOF"
# Begin /etc/hosts

127.0.0.1 localhost.localdomain localhost
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters

# End /etc/hosts
EOF

# 9.5. Configuring the System Clock
# Not needed for UTC

# cat > /etc/adjtime << "EOF"
# 0.0 0 0.0
# 0
# LOCAL
# EOF

# 9.6. Configuring the Linux Console
cat > /etc/vconsole.conf << "EOF"
KEYMAP=br-abnt2
EOF

# 9.7. The Bash Shell Startup Files
cat > /etc/profile << "EOF"
# Begin /etc/profile

export LANG=pt_BR.UTF-8

# End /etc/profile
EOF

# 9.8. Creating the /etc/inputrc File
cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF

# 9.9. Creating the /etc/shells File
cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF

# 10.2. Creating the /etc/fstab File
cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point  type     options             dump  fsck
#                                                              order

/dev/sda1      /            ext4     defaults            1     1
proc           /proc        proc     nosuid,noexec,nodev 0     0
sysfs          /sys         sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts     devpts   gid=5,mode=620      0     0
tmpfs          /run         tmpfs    defaults            0     0
devtmpfs       /dev         devtmpfs mode=0755,nosuid    0     0

# End /etc/fstab
EOF

cd /sources

# 10.3. Linux-5.13.12
begin linux-5.13.12 tar.xz
make mrproper
make -j4 defconfig
make -j4
make -j4 modules_install
cp -iv arch/x86/boot/bzImage /boot/vmlinuz-5.13.12-lfs-11.0
cp -iv System.map /boot/System.map-5.13.12
cp -iv .config /boot/config-5.13.12
install -d /usr/share/doc/linux-5.13.12
cp -r Documentation/* /usr/share/doc/linux-5.13.12
finish

# 10.3.2. Configuring Linux Module Load Order
install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF

# 10.4. Using GRUB to Set Up the Boot Process
# grub-install /dev/sdb
# cat > /boot/grub/grub.cfg << "EOF"
# Begin /boot/grub/grub.cfg
# set default=0
# set timeout=5
# insmod ext2
# set root=(hd0,1)
# menuentry "GNU/Linux, Linux 5.13.12-lfs-11.0" {
#        linux   /boot/vmlinuz-5.13.12-lfs-11.0 root=/dev/sda1 ro
# }
# EOF

# 11.1. The End
echo 11.0-systemd > /etc/lfs-release
cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="11.0-systemd"
DISTRIB_CODENAME="Linux From Scratch"
DISTRIB_DESCRIPTION="Linux From Scratch"
EOF
cat > /etc/os-release << "EOF"
NAME="Linux From Scratch"
VERSION="11.0-systemd"
ID=lfs
PRETTY_NAME="Linux From Scratch 11.0-systemd"
VERSION_CODENAME="Linux From Scratch"
EOF

echo "[lfs-scripts] The end"
