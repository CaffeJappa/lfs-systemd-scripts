# LFS-Systemd-Scripts
Instructions and scripts to build Linux From Scratch (LFS), version 11.0-systemd, as simply as possible.

# Foreword

This guide does not replace reading the whole LFS book. It is highly recommended that you read it at least once. If you haven't already, come here later after reading and use the automated scripts provided here.

This build was made to be accomplished inside a virtual machine, but you can use any tool (or real HD/SSD) of your personal preference. Feel free to use your GNU/Linux distribution of choice, just be sure to install the development packages available.

The packages needed to build LFS can be downloaded from [here](http://ftp.osuosl.org/pub/lfs/lfs-packages/lfs-packages-11.0.tar) (443 MB), other mirrors are available [here](http://linuxfromscratch.org/lfs/download.html) (look for the "LFS HTTP/FTP Sites" section at the bottom, the file you'll need is `lfs-packages-11.0.tar`).

All compilations in the scripts made by a ``make`` are configured to use parallelism 4 (``-j4``), if you need to change this, edit the scripts.

# Build Instructions

**Run commands below as root.**

> 1.0. Create a partition and a filesystem in the hard disk (in this case, `/dev/sda`).
```
# fdisk /dev/sda
  Command (m for help): n
  Partition number (1-128, default 1): 
  First sector (2048-30842846, default 2048): 
  Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-30842846, default 30842846):
  Command (m for help): w
```
* If you are gonna install with EFI, first create a new partition with `n`, type in Last Sector `+512M`, type `t` after creating it and then type `1`. Then follow the instructions up here

> 1.1. Create a filesystem, a mount point, and mount it.
```
# mkfs.ext4 /dev/sda1
# mkdir /mnt/lfs
# mount /dev/sda1 /mnt/lfs
```
* EFI: `mkfs.fat -F32 /dev/sda2`, `mkdir -p /mnt/lfs/boot/efi`, `mount /dev/sda2 /mnt/lfs/efi`
> 1.2. Add the following line to the root `.bashrc`.
```
export LFS=/mnt/lfs
```
> 1.2.1. Source the file.
```
# source .bashrc
```
## Preparing the Environment

> 1.0. Download all the packages and extract them to `$LFS/sources`.
```
# cd $LFS
# cp /<location_of_the_packages>/lfs-packages-11.0.tar .
# tar xf lfs-packages-11.0.tar
# mv 11.0 sources/
# chmod -v a+wt $LFS/sources
```
> 1.0.1. If you've downloaded GRUB EFI packages, extract them into your `$LFS/sources` folder.
```
# cp /<location_of_GRUB-EFI>/GRUB-EFI.tar .
# mkdir $LFS/sources-grub/
# tar xf GRUB-EFI.tar $LFS/sources-grub/
# chmod -v a+wt $LFS/sources-grub
```

> 1.1. Copy all the shell scripts from this repository to your `$LFS` directory.
```
# cp /<location_of_the_scripts>/*.sh $LFS
```

> 1.2. Create the basic filesystem for LFS.
```
# mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}

# for i in bin lib sbin; do
ln -sv usr/$i $LFS/$i
done

# case $(uname -m) in
x86_64) mkdir -pv $LFS/lib64 ;;
esac

# mkdir -pv $LFS/tools
```

> 1.3. Create a lfs user, used during the initial build process.
```
# groupadd lfs
# useradd -s /bin/bash -g lfs -m -k /dev/null lfs
# passwd lfs
```

> 1.3.1. Make lfs own the filesystem.
```
# chown -R lfs:lfs $LFS/*
# chown lfs:lfs $LFS
```

> 1.3.2. Log in as the lfs user.
```
# su - lfs
```

**Run commands below as lfs.**

> 1.4. Create a .bash_profile file.
```
$ cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF
```

> 1.4.1 Create a .bashrc file.
```
$ cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/usr/bin
if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
PATH=$LFS/tools/bin:$PATH
CONFIG_SITE=$LFS/usr/share/config.site
export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
EOF

$ source ~/.bashrc
```

## Compiling the Cross Toolchain

> 1.0. Run the `lfs-cross.sh` script, which will build the cross toolchain and cross compiling temporary tools from LFS chapters 5 and 6.
``` 
$ sh $LFS/lfs-cross.sh | tee $LFS/lfs-cross.log
```

> 1.1. Exit from the lfs user to become root again.
```
$ exit
```

## Preparing Chroot Environment
**Run commands below as root.**

> 1.0. Make root own the entire filesystem again.
```
# chown -R root:root $LFS/*
# chown root:root $LFS
```

> 1.1. Prepare virtual kernel file systems.
```
# mkdir -pv $LFS/{dev,proc,sys,run}
# mknod -m 600 $LFS/dev/console c 5 1
# mknod -m 666 $LFS/dev/null c 1 3
# mount -v --bind /dev $LFS/dev
# mount -v --bind /dev/pts $LFS/dev/pts
# mount -vt proc proc $LFS/proc
# mount -vt sysfs sysfs $LFS/sys
# mount -vt tmpfs tmpfs $LFS/run
# if [ -h $LFS/dev/shm ]; then
mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi
```

> 1.2. Enter the chroot environment.
```
# chroot "$LFS" /usr/bin/env -i   \
HOME=/root                  \
TERM="$TERM"                \
PS1='(lfs chroot) \u:\w\$ ' \
PATH=/usr/bin:/usr/sbin     \
/bin/bash --login +h
```
* Notice that you'll have no name, and that's normal. You'll be already running as root.

> 1.3. Create essential directories, files and symlinks.
```
# mkdir -pv /{boot,home,mnt,opt,srv}
# mkdir -pv /etc/{opt,sysconfig}
# mkdir -pv /lib/firmware
# mkdir -pv /media/{floppy,cdrom}
# mkdir -pv /usr/{,local/}{include,src}
# mkdir -pv /usr/local/{bin,lib,sbin}
# mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
# mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
# mkdir -pv /usr/{,local/}share/man/man{1..8}
# mkdir -pv /var/{cache,local,log,mail,opt,spool}
# mkdir -pv /var/lib/{color,misc,locate}

# ln -sfv /run /var/run
# ln -sfv /run/lock /var/lock

# install -dv -m 0750 /root
# install -dv -m 1777 /tmp /var/tmp

# ln -sv /proc/self/mounts /etc/mtab

# cat > /etc/hosts << EOF
127.0.0.1  localhost $(hostname)
::1        localhost
EOF

# cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/bin/false
systemd-bus-proxy:x:72:72:systemd Bus Proxy:/:/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/bin/false
systemd-network:x:76:76:systemd Network Management:/:/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/bin/false
systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF

# cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-bus-proxy:x:72:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
uuidd:x:80:
systemd-oom:x:81:81:
wheel:x:97:
nogroup:x:99:
users:x:999:
EOF

# touch /var/log/{btmp,lastlog,faillog,wtmp}
# chgrp -v utmp /var/log/lastlog
# chmod -v 664  /var/log/lastlog
# chmod -v 600  /var/log/btmp

# exec /bin/bash --login +h
```
* Now you have a name! ;)
> 1.4. Run the `lfs-chroot.sh` script, which will build additional temporary tools.
``` 
# sh /lfs-chroot.sh | tee /lfs-chroot.log
```

> 1.4.1 Clean up some unnecessary files and folders.
```
# rm -rf /usr/share/{info,man,doc}/*
# find /usr/{lib,libexec} -name \*.la -delete
# rm -rf /tools
```

## Compile Essential Softwares

> 1.0. For the final build phase, run the `lfs-system.sh` script.
``` 
# sh /lfs-system.sh | tee /lfs-system.log
```
* This can take up an hour or two.

> 1.1. You must now set a password for the root user.
```
# passwd root
```

> 1.2. Logout from the chroot environment and re-enter it with updated configuration:
```
# logout

# chroot "$LFS" /usr/bin/env -i          \
HOME=/root TERM="$TERM"            \
PS1='(lfs chroot) \u:\w\$ '        \
PATH=/usr/bin:/usr/sbin            \
/bin/bash --login
```
## The End

> 1.0. Run the final script to configure the rest of the system.
* GRUB is not configured to be installed in the script. If you're a MBR user, edit the file and uncomment the GRUB (10.4 header) lines (and configure it to your partitions). You don't need to do this if doing on a real HD/SSD, just open your terminal (of the host system) and run `# grub-mkconfig -o /boot/grub/grub.cfg`.

```
# sh /lfs-final.sh | tee /lfs-final.log
```

> 1.0.1. GRUB EFI script.
```
# sh /lfs-grub-uefi.sh | tee /lfs-grub-uefi.log
```

> 1.0.2. Edit fstab (EFI).
```
# logout
# rm $LFS/etc/fstab
# cat > $LFS/etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point  type     options             dump  fsck
#                                                              order

/dev/sda1      /boot/efi             vfat     rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro            0     2
/dev/sda2      /            ext4     defaults            1     1     
proc           /proc        proc     nosuid,noexec,nodev 0     0
sysfs          /sys         sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts     devpts   gid=5,mode=620      0     0
tmpfs          /run         tmpfs    defaults            0     0
devtmpfs       /dev         devtmpfs mode=0755,nosuid    0     0

# End /etc/fstab
EOF
```
Congratulations, you did it! Now you may use the system for whatever you want. It will be bootable (if you configured it to be so) and fully functional. Enjoy!
