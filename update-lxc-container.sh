#!/bin/bash

#title:       upgrade-lxc-container.sh
#description: Mounts lxc container filesystem on the host instance and runs do-release-upgrade in chroot environment
#author:      Teemuko
#date:        1.8.2016
#version:     1.0    
#usage:       <path>/upgrade-lxc-container.sh


if [ $# = 0 ] ; then
        echo "Usage: upgrade-lxc-container.sh <container_name> [<--cleanup>/<--mount>/<--umount>/<arguments for do-release-upgrade>]"
        echo "Example: upgrade-lxc-container.sh mycontainer"
        exit 1
fi


configfile=/var/lib/lxc/$1/config

# Find container root filesystem path from the config file
if [ -f ${configfile} ]; then
    echo "Reading LXC config" $configfile >&2

    container_rootfs=$(sed -ne "s/lxc.rootfs *= *\([^ ]*\)*/\1/p" /var/lib/lxc/$1/config)
    if ! [ $container_rootfs ] 
        then
        echo "Can't find rootfs parameter " 
        exit 1
    fi
else
    echo "There is no configuration file called ${configfile}"
    exit 1
fi


echo LXC container $1 root path found to be $container_rootfs


#test that rootfs looks like rootfs
if ! [ -d $container_rootfs/etc ]
then
        echo ERROR: This does not seem to be lxc rootfs $container_rootfs
        exit 1
fi


echo "Stopping container..."
lxc-stop -n $1

echo
echo "Mounting container filesystems..."
# Mount the filessystems manually
mount -t proc proc -o nodev,noexec,nosuid $container_rootfs/proc
mount -t sysfs sysfs $container_rootfs/sys
mount -t devpts devpts $container_rootfs/dev/pts

echo
echo "Container file system proc, sysfs and devpts should be now mounted:"
mount | grep $1

# Function to unmount lxc filesystems
umountlxc() {
echo
echo "Unmounting lxc filsystems..."
umount $container_rootfs/dev/pts
umount $container_rootfs/sys
umount $container_rootfs/proc
echo
echo "Please note that upgrade has installed openssh-server and update-manager-core"
echo "Run with --cleanup switch to remove them after upgrade."
echo
echo "Container is left inactive after the upgrade"
}


# ERROR HANDLING: After any errors, unmount lxc containers
trap umountlxc ERR 

# Check what user wants to do:
case "$2" in
   --mount)
        echo
        echo "LXC-container filesystems mounted as pts, sys and proc"
        echo "Run with --unmount switch to unmount these"
   ;;

   --umount)
        umountlxc
   ;;

   --cleanup)
        echo "Cleanup!"
        echo "Removing ssh and update-manager"
        chroot $container_rootfs apt-get remove openssh-server update-manager-core 
   ;;

   *)
        # Perform the update
        echo 
        echo Chrooting to $container_rootfs
        echo
        
        echo "update-manager set to prompt updates for:"
        chroot $container_rootfs cat /etc/update-manager/release-upgrades | grep Prompt
        chroot $container_rootfs apt-get dist-upgrade
        chroot $container_rootfs apt-get install openssh-server update-manager-core 
        chroot $container_rootfs /usr/bin/do-release-upgrade $2
        umountlxc
   ;;
esac
