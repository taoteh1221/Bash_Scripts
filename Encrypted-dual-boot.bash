#!/bin/bash

# USAGE: VIA PARAMS BELOW, must run pre-setup, install OS, then run post-setup.
# (Dual-boot with windows, encrypting ONLY linux ROOT partition)
# ./Encrypted-dual-boot.bash pre 
# ./Encrypted-dual-boot.bash post


######################################
# SETTINGS - START
######################################


# Set boot partition location
BOOT_PART="/dev/YOUR_BOOT_DEVICE_PARTITION_HERE"

# Set root partition location
ROOTFS_PART="/dev/YOUR_ROOT_DEVICE_PARTITION_HERE"


######################################
# SETTINGS - END
######################################


# https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux

if hash tput > /dev/null 2>&1; then

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`

reset=`tput sgr0`

else

red=``
green=``
yellow=``
blue=``
magenta=``
cyan=``

reset=``

fi


######################################


if [ "$EUID" -ne 0 ]; then
 echo " " 
 echo "${red}Please run WITH 'sudo / root' PERMISSIONS.${reset}"
 echo " "
 echo "${cyan}Exiting...${reset}"
 echo " "
 exit
fi


######################################


# "pre" param passed
if [ "$1" == "pre" ]; then

cryptsetup luksFormat $ROOTFS_PART

cryptsetup luksOpen $ROOTFS_PART cryptroot

sleep 1

pvcreate /dev/mapper/cryptroot

vgcreate vgroot /dev/mapper/cryptroot

lvcreate -n lvroot -l 100%FREE vgroot

echo " "
echo "${cyan}Setup of encrypted partitions complete, you can proceed with OS installation${reset}"
echo " "

# "post" param passed
elif [ "$1" == "post" ]; then

mount /dev/mapper/vgroot-lvroot /mnt

mount $BOOT_PART /mnt/boot

mount --bind /dev /mnt/dev

# Get device UUID
ROOTFS_UUID=$(blkid $ROOTFS_PART | cut -d \" -f2)
          
# Don't nest / indent, or it could malform the settings            
read -r -d '' CRYPTTAB_SETUP <<- EOF
\r
# <target name> <source device> <key file> <options>
cryptroot UUID=$ROOTFS_UUID none luks,discard
\r
EOF

# Export $CRYPTTAB_SETUP to chroot
export CRYPTTAB_SETUP=$CRYPTTAB_SETUP

# chroot, and setup to mount at boot
chroot /mnt /bin/bash <<"EOT"
mount -t proc proc /proc
mount -t sysfs sys /sys
mount -t devpts devpts /dev/pts
touch /etc/crypttab
echo -e "$CRYPTTAB_SETUP" > /etc/crypttab
update-initramfs -k all -c
sleep 1
cat /etc/crypttab
EOT

sleep 1

echo " "
echo "${cyan}Setup / install is FULLY complete, you must now reboot for changes to take effect.${reset}"
echo " "
			 
fi


######################################





