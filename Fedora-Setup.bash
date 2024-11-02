#!/bin/bash


####
# USAGE:
####
# "chmod +x Fedora-Setup.bash" will make this script runnable / executable
####
# "./Fedora-Setup.bash" runs this script in NORMAL setup mode
####
# "./Fedora-Setup.bash enroll_secureboot_mok" runs this script in ENROLL MOK (Machine Owner Key) setup mode,
# for boot module signing, on secure boot enabled systems (ADDS boot module signing support)
####
# "./Fedora-Setup.bash reset_secureboot_mok" runs this script in RESET MOK (Machine Owner Key) setup mode,
# for boot module signing, on secure boot enabled systems
# (RESETS / REMOVES boot module signing support [HELPS IF YOU HAVE MOK ISSUES...THEN YOU CAN RE-ENROLL AFTERWARDS])
####


# Config

PREFERRED_HOSTNAME="taoteh1221-Desktop-Asus-Lin"

SECONDS_TO_SHOW_BOOT_MENU=10

# END Config


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


# Update PACKAGES (NOT operating system version)
sudo dnf upgrade -y

sleep 3

# Install building tools
sudo dnf install -y --skip-broken kernel-devel-`uname -r` kernel-headers kernel-devel gcc make dkms acpid akmods pkgconfig elfutils-libelf-devel qt5-qtx11extras

# Install build + dev tools / games / media support / etc
sudo dnf group install -y --skip-broken 3d-printing audio c-development container-management editors d-development development-tools games rpm-development-tools sound-and-video vlc

sleep 3


# If we are DELETING a MOK (Machine Owner Key), for seure boot module signing
if [ "$1" == "reset_secureboot_mok" ]; then

echo " "
echo "${yellow}Create a PIN to enter, which you will need after you reboot your computer, to REMOVE your MOK (Machine Owner Key):"
echo "${reset} "

sudo mokutil --reset

echo " "
echo "${red}YOU MUST NOW REBOOT YOUR COMPUTER, INITIATE 'MOK Management', CHOOSE 'Reset MOK / Yes' -> 'Continue / Reboot', ENTER THE PIN YOU CREATED / REBOOT, to remove MOK module signing!"
echo "${reset} "

echo " "
echo "Exiting MOK reset..."
echo " "

# EXIT
exit

# If we are CREATING a MOK (Machine Owner Key), for secure boot module signing
elif [ "$1" == "enroll_secureboot_mok" ]; then

    
     # Check to see if MOK keys have already been setup
     if [ ! -f "/var/lib/shim-signed/mok/MOK.priv" ] && [ ! -f "/var/lib/shim-signed/mok/MOK.der" ]; then

     # Make sure we have openssl installed
     sudo dnf install -y openssl

     sleep 3

     sudo mkdir -p /var/lib/shim-signed/mok

     sleep 3

     echo " "
     echo "${yellow}Create a MOK (Machine Owner Key) security certificate, for use with secure boot module signing:"
     echo "${reset} "

     sudo openssl req -nodes -new -x509 -newkey rsa:2048 -outform DER -addext "extendedKeyUsage=codeSigning" -keyout /var/lib/shim-signed/mok/MOK.priv -out /var/lib/shim-signed/mok/MOK.der

     fi


echo " "
echo "${yellow}Create a PIN to enter, which you will need after you reboot your computer, to ENROLL your MOK (Machine Owner Key), for secure boot module signing:"
echo "${reset} "

sudo mokutil --import /var/lib/shim-signed/mok/MOK.der

echo " "
echo "${cyan}Finished MOK setup..."
echo "${reset} "

MOK_SETUP=1

fi
# END If setting up MOK (for secure boot module updating)


# Check to see if MOK secure boot module signing KEYS have already been setup
if [ ! -f "/var/lib/shim-signed/mok/MOK.priv" ] && [ ! -f "/var/lib/shim-signed/mok/MOK.der" ]; then

echo " "
echo "${red}MOK (Machine Owner Key) secure boot module signing has NOT been setup yet, RERUN this script with the 'enroll_secureboot_mok' parameter:"
echo "${cyan}./Fedora-Setup.bash enroll_secureboot_mok"
echo "${reset} "
echo "Exiting Fedora setup..."
echo " "

# EXIT
exit

fi


# Secure user home directory, from other accounts snooping it
sudo chmod 750 /home/$USER

# Use UTC as base clock time (to avoid clock skew, on dual boot [Win11] systems)
# As user
timedatectl set-local-rtc 0
# As admin too
sudo timedatectl set-local-rtc 0

# Enable FUSION repos
sudo dnf install -y \
  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

sudo dnf install -y \
  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

sleep 3

# Refresh cache, to include the new repos
sudo dnf makecache

sleep 3

# Install cron / fire it up (will persist between reboots)
sudo dnf install -y cronie

sleep 3

sudo systemctl start crond.service

sleep 3

# Install generic graphics card libraries
sudo dnf install -y libglvnd-glx libglvnd-opengl libglvnd-devel

# Install cinnamon desktop
sudo dnf install -y @cinnamon-desktop-environment 

#Install KDE
sudo dnf install -y @kde-desktop

sleep 3

# Install dropbox for nemo / dolphin (file explorers)
sudo dnf install -y nemo-dropbox dolphin-plugins

#Install LXDE
sudo dnf group install -y lxde-desktop

# Install preferred file archiving tools
sudo dnf install -y p7zip p7zip-plugins unrar ark engrampa

# Install preferred disk tools
sudo dnf install -y gparted

# Install samba tools
sudo dnf install -y cifs-utils

# Install home directory encryption tools, openssl
sudo dnf install -y ecryptfs-utils openssl

# Install 'passwords and keys' and Kpgp (PGP import / export) interfaces
sudo dnf install -y seahorse kpgp

# Install uboot tools (for making ARM disk images bootable, if device is NOT supported by arm-image-installer)
sudo dnf install -y uboot-tools uboot-images-armv8 rkdeveloptool gdisk

# IOT (ARM CPU) image installer (fedora raspi images to microsd, etc)
sudo dnf install -y arm-image-installer

# Install official google chrome (if you "enabled 3rd party repositories" during OS installation),
# AND evolution email / calendar
sudo dnf config-manager --enable google-chrome
sudo dnf install -y google-chrome-stable evolution

# Library needed for FileZilla Pro
sudo dnf install -y libxcrypt-compat

# Install virtualbox (from RPMfusion), Virtual Machine Manager, and associated tools
sudo dnf install -y --skip-broken VirtualBox virt-manager edk2-ovmf swtpm-tools spice-vdagent

# Install darkplaces-quake, steam, AND lutris
sudo dnf install -y darkplaces-quake darkplaces-quake-server steam lutris

# Set default editors to nano
DEFAULT_EDITOR_CHECK=$(sed -n '/export EDITOR/p' ~/.bash_profile)
DEFAULT_VISUAL_CHECK=$(sed -n '/export VISUAL/p' ~/.bash_profile)


if [ "$DEFAULT_EDITOR_CHECK" == "" ]; then
sudo bash -c 'echo "export EDITOR=nano" >> ~/.bash_profile'
else
sudo sed -i 's/export EDITOR=.*/export EDITOR=nano/g' ~/.bash_profile > /dev/null 2>&1
fi


if [ "$DEFAULT_VISUAL_CHECK" == "" ]; then
sudo bash -c 'echo "export VISUAL=nano" >> ~/.bash_profile'
else
sudo sed -i 's/export VISUAL=.*/export VISUAL=nano/g' ~/.bash_profile > /dev/null 2>&1
fi


# Disable sleep mode, IF NOBODY LOGS IN VIA INTERFACE
# https://discussion.fedoraproject.org/t/gnome-suspends-after-15-minutes-of-user-inactivity-even-on-ac-power/79801
sudo -u gdm dbus-run-session gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0 > /dev/null 2>&1

# Set hostname
sudo hostnamectl set-hostname $PREFERRED_HOSTNAME

# Make grub boot menu ALWAYS SHOW (even on NON-dual-boot setups)
sudo grub2-editenv - unset menu_auto_hide

# Have grub wait 10 seconds before auto-booting
sudo sed -i "s/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=${SECONDS_TO_SHOW_BOOT_MENU}/g" /etc/default/grub > /dev/null 2>&1

# Have grub show verbose startup / shutdown screens
sudo sed -i 's/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=""/g' /etc/default/grub > /dev/null 2>&1

# Remove WINDOWS BOOT MANAGER from grub
# (MODERN SECURE BOOT ENABLED setups now usually require booting windows from the UEFI boot menu hotkey at startup,
# IF YOU HAVE A BITLOCKER-ENCRYPTED [Windows 11 Pro] windows operating system, otherwise you force-enter "recovery mode")
OS_PROBER_CHECK=$(sudo sed -n '/GRUB_DISABLE_OS_PROBER/p' /etc/default/grub)


if [ "$OS_PROBER_CHECK" == "" ]; then
sudo bash -c 'echo "GRUB_DISABLE_OS_PROBER=true" >> /etc/default/grub'
else
sudo sed -i 's/GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=true/g' /etc/default/grub > /dev/null 2>&1
fi


# If running a geforce graphics card, install the drivers
NVIDIA_GEFORCE=$(lspci | grep -Ei 'GeForce')


if [ "$NVIDIA_GEFORCE" != "" ]; then

#https://discussion.fedoraproject.org/t/nvidia-drivers-with-secure-boot-no-longer-working/84444
sudo dnf reinstall -y linux-firmware

sleep 3

sudo dnf install -y --skip-broken akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-libs xorg-x11-drv-nvidia-libs.i686

sleep 3

# https://forums.developer.nvidia.com/t/major-kde-plasma-desktop-frameskip-lag-issues-on-driver-555/293606
sudo grubby --update-kernel=ALL --args=nvidia.NVreg_EnableGpuFirmware=0

fi


# Update grub bootloader
sudo grub2-mkconfig -o /etc/grub2.cfg

# Run virtualbox config AT THE END OF THIS SCRIPT,
# SO ANY SECURE BOOT SETUP NOTICES / INSTRUCTIONS DISPLAY LAST!
sudo /sbin/vboxconfig

# FULLY lock down all ports with the firewall (already installed / activated by default in fedora),
# by changing the default zone to the included SERVER default setup
# USE WITH CAUTION, THIS EVEN LOCKS DOWN RELATED INCOMING (INITIATED BY CLIENT REQUEST LOCALLY...BROWSER, INTERNET RADIO, ETC)!!!!!
#sudo firewall-cmd --set-default-zone=FedoraServer


if [ "$NVIDIA_GEFORCE" != "" ]; then

echo " "
echo "${red}ALWAYS USE FEDORA'S BUNDLED GEFORCE DRIVERS, AS THE MANUFACTURER-SUPPLIED DRIVERS ARE DISTRO-AGNOSTIC (NOT TAILORED SPECIFICALLY TO FEDORA), AND CAN CAUSE ISSUES!"
echo "${reset} "

fi


if [ "$MOK_SETUP" = "1" ]; then

echo " "
echo "${red}YOU *MUST* NOW REBOOT YOUR COMPUTER, INITIATE 'MOK Management', CHOOSE 'Enroll MOK' -> 'Continue', ENTER THE PIN YOU CREATED / REBOOT, to enable MOK module signing!"
echo "${reset} "

fi


echo " "
echo "Exiting Fedora setup..."
echo " "
