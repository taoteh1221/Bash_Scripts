#!/bin/bash

# Copyright 2024 GPLv3, Open Crypto Tracker by Mike Kilday: Mike@DragonFrugal.com (leave this copyright / attribution intact in ALL forks / copies!)

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
# for RESETTING boot module signing, on secure boot enabled systems
# (RESETS / REMOVES boot module signing support [HELPS IF YOU HAVE MOK ISSUES...THEN YOU CAN RE-ENROLL AFTERWARDS])
####
# "./Fedora-Setup.bash sign_secureboot_modules" runs this script in SIGN MODULES (for secure boot) setup mode,
# for boot module loading, on secure boot enabled systems (ENABLES boot module loading [in secure boot mode])
# YOU MUST WAIT, AND RUN THIS MODULE-SIGNING MODE AFTER INSTALLING DRIVERS, AND AFTER ENROLLING THE MOK KEY!
####
# "./Fedora-Setup.bash arm_xz_image_to_device" runs this script in ARM (xz) disk image to storage device setup mode,
# for downloading and installing an ARM disk image to a storage device (to boot an OS from that storage device, etc)
####


# Config

PREFERRED_HOSTNAME="rock5b"

SECONDS_TO_SHOW_BOOT_MENU=10

ENABLE_COCKPIT_REMOTE_ADMIN="no" # "no" / "yes"

HEADLESS_SETUP_ONLY="yes" # "no" / "yes"

# END Config


######################################

# Are we running on an ARM-based CPU?
IS_ARM=$(uname -r | grep "aarch64")

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


# Get logged-in username (if sudo, this works best with logname)
TERMINAL_USERNAME=$(logname)

# If logname doesn't work, use the $SUDO_USER or $USER global var
if [ -z "$TERMINAL_USERNAME" ]; then

    if [ -z "$SUDO_USER" ]; then
    TERMINAL_USERNAME=$USER
    else
    TERMINAL_USERNAME=$SUDO_USER
    fi

fi


# Quit if ACTUAL USERNAME is root
if [ "$TERMINAL_USERNAME" == "root" ]; then 

 echo " "
 echo "${red}Please run as a NORMAL USER WITH 'sudo' PERMISSIONS (NOT LOGGED IN AS 'root').${reset}"
 echo " "
 echo "${cyan}Exiting...${reset}"
 echo " "
 
 exit

# Quit if running with sudo (since we want to run a few things as the user in here)
elif [ "$EUID" == 0 ]; then 

echo " "
echo "${red}Please run #WITHOUT# 'sudo' PERMISSIONS.${reset}"
echo " "
echo "${cyan}Exiting...${reset}"
echo " "
             
exit
             
fi


######################################


# Install an ARM disk image to a storage device
if [ "$IS_ARM" != "" ] && [ "$1" == "arm_xz_image_to_device" ] && [ "$2" != "" ] && [ "$3" != "" ]; then

# Install curl
sudo dnf install -y curl

sleep 2

URL_STATUS=$(curl --head --silent --write-out "%{http_code}" --output /dev/null ${3})


    if [ -f "$2" ] && [ $URL_STATUS -eq 200 ]; then

    echo "${yellow} "
    read -n1 -s -r -p $"ANY PREVIOUS DATA ON DEVICE '${2}' WILL BE ERASED. Press Y to continue (or press N to exit)..." key
    echo "${reset} "
     
         if [ "$key" = 'y' ] || [ "$key" = 'Y' ]; then
         echo " "
         echo "${green}Continuing...${reset}"
         echo " "
         else
         echo " "
         echo "${green}Exiting...${reset}"
         echo " "
         exit
         fi
                    
    echo " "
    echo "${cyan}Downloading and writing XZ disk image to device '${2}', please wait..."
    echo "${reset} "

    wget --no-cache -O disk-image.img.xz ${3}

    sleep 2

    xz -dc disk-image.img.xz | sudo dd of=${2} bs=4k status=progress

    sleep 2
    
    echo " "
    echo "${cyan}XZ disk image finished writing to device '${2}'."
    echo "${reset} "

    elif [ ! -f "$2" ]; then

    echo " "
    echo "${red}Device '${2}' does NOT exist."
    echo "${reset} "

    elif [ $URL_STATUS -ne 200 ]; then

    echo " "
    echo "${red}XZ disk image parameter MUST BE a web link, your entered web link address '${3}' returned an error code: ${URL_STATUS}"
    echo "${reset} "

    fi


exit

elif [ "$IS_ARM" == "" ]; then

echo " "
echo "${red}Your system does NOT appear to be ARM-based."
echo "${reset} "

exit

elif [ "$2" == "" ]; then

echo " "
echo "${red}Device parameter was NOT included."
echo "${reset} "

exit

elif [ "$3" == "" ]; then

echo " "
echo "${red}XZ disk image parameter was NOT included."
echo "${reset} "

exit

fi


######################################


# Update PACKAGES (NOT operating system version)
sudo dnf upgrade -y

sleep 3

# Install building / system tools
sudo dnf install -y --skip-broken kernel-devel-`uname -r` kernel-headers kernel-devel kernel-tools gcc make dkms acpid akmods pkgconfig elfutils-libelf-devel

# Install dev tools
sudo dnf group install -y --skip-broken c-development container-management d-development development-tools rpm-development-tools

# Install samba tools
sudo dnf install -y cifs-utils

# Install home directory encryption tools, openssl
sudo dnf install -y --skip-broken ecryptfs-utils openssl

# Install uboot tools (for making ARM disk images bootable)
sudo dnf install -y --skip-broken uboot-tools uboot-images-armv8 rkdeveloptool gdisk

# IOT (ARM CPU) image installer (fedora raspi / radxa / other images to microsd, etc), AND enable 'updates-testing' repo
# https://fedoraproject.org/wiki/Architectures/ARM/Installation#Arm_Image_Installer
sudo dnf install --enablerepo=updates-testing -y arm-image-installer

# Add repo to have various FEDORA-COMPATIBLE uboot images
# (LAST PARAMETER IS OPTIONAL [OR REQUIRED, IF INSTALLED ON A DIFFERENT DEVICE WITHOUT A MATCHING ARCHITECTURE])
sudo dnf copr enable pbrobinson/u-boot fedora-41-aarch64

# Get Fedora uboot images (are stored in: /usr/share/uboot/), for device flashing
sudo dnf install uboot-images-copr

####
# Fedora u-boot USAGE...
####
# General U-boot Flashing Notice:
# https://lists.fedoraproject.org/archives/list/arm@lists.fedoraproject.org/thread/G3QENPQCNFTXSM5FZZLEUA6B7J4QKFXV/
# Flash to microsd for USB boot, or to onboard SPI for M2 boot (see further below for Fedora-compatible onboard SPI flash directions,
# DO NOT USE Radxa's [or any other OEM's] SPI flash method for Fedora support, as it's NOT compatible, and can brick your device!)
####
# Onboard SPI Flashing:
# https://nullr0ute.com/2021/05/fedora-on-the-pinebook-pro/
# (CHANGE 'target' PARAM VALUE TO MATCH YOUR DEVICE, OR JUST KEEP THE PINEBOOK PRO TARGET,
# AND MANUALLY OVERWRITE THE UBOOT FILES CREATED ON THE MICROSD, WITH YOUR DEVICE'S FILES FROM: /usr/share/uboot/)


# If we are DELETING a MOK (Machine Owner Key), for secure boot module signing
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

# Sign secure boot modules
elif [ "$1" == "sign_secureboot_modules" ]; then

sudo akmods --force --rebuild

echo " "
echo "${red}REBOOT YOUR MACHINE ONE LAST TIME, TO ALLOW LOADING ALL MODULES IN SECURE BOOT MODE."
echo "${reset} "
echo "Finished module-signing setup..."
echo " "

exit

fi
# END CLI params logic


sleep 3


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


# If we are enabling cockpit, for remote admin UI ability
if [ "$ENABLE_COCKPIT_REMOTE_ADMIN" == "yes" ]; then

sudo dnf install -y cockpit

sleep 3

sudo systemctl enable --now cockpit.socket

sudo firewall-cmd --add-service=cockpit

sudo firewall-cmd --add-service=cockpit --permanent

fi


# Set default (user) editors to nano
DEFAULT_EDITOR_CHECK=$(sed -n '/export EDITOR/p' ~/.bash_profile)
DEFAULT_VISUAL_CHECK=$(sed -n '/export VISUAL/p' ~/.bash_profile)


if [ "$DEFAULT_EDITOR_CHECK" == "" ]; then
bash -c 'echo "export EDITOR=nano" >> ~/.bash_profile'
else
sed -i 's/export EDITOR=.*/export EDITOR=nano/g' ~/.bash_profile > /dev/null 2>&1
fi


if [ "$DEFAULT_VISUAL_CHECK" == "" ]; then
bash -c 'echo "export VISUAL=nano" >> ~/.bash_profile'
else
sed -i 's/export VISUAL=.*/export VISUAL=nano/g' ~/.bash_profile > /dev/null 2>&1
fi


# Set hostname
sudo hostnamectl set-hostname $PREFERRED_HOSTNAME

# Secure user home directory, from other accounts snooping it
sudo chmod 750 /home/$USER

# Use UTC as base clock time (to avoid clock skew, on dual boot [Win11] systems)
# As user
timedatectl set-local-rtc 0
# As admin too
sudo timedatectl set-local-rtc 0

sleep 3

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


##############################################################################
##############################################################################

# If we are doing a graphical interface setup (NOT headless / terminal-only)
if [ "$HEADLESS_SETUP_ONLY" == "no" ]; then

# GROUP INSTALLS for games / media support / etc
sudo dnf group install -y --skip-broken audio 3d-printing editors games sound-and-video vlc

# Install generic graphics card libraries, and other interface-related libraries
sudo dnf install -y --skip-broken libglvnd-glx libglvnd-opengl libglvnd-devel qt5-qtx11extras

# Install cinnamon desktop
sudo dnf install -y @cinnamon-desktop-environment

#Install KDE
sudo dnf install -y @kde-desktop

sleep 3

# KDE double click interval
KDE_MOUSE_CHECK=$(sed -n '/DoubleClickInterval/p' ~/.config/kdeglobals)


    if [ "$KDE_MOUSE_CHECK" == "" ]; then
    # Place directly below [KDE], if it does NOT exist
    sed -i '/\[KDE\]/a DoubleClickInterval=1000' ~/.config/kdeglobals > /dev/null 2>&1
    else
    # Replace with preferred setting, if exists
    sed -i 's/DoubleClickInterval=.*/DoubleClickInterval=1000/g' ~/.config/kdeglobals > /dev/null 2>&1
    fi


# Install dropbox for nemo / dolphin (file explorers)
sudo dnf install -y --skip-broken nemo-dropbox dolphin-plugins

#Install LXDE
sudo dnf group install -y lxde-desktop

# Install preferred file archiving tools
sudo dnf install -y --skip-broken p7zip p7zip-plugins unrar ark engrampa

# Install gparted, for partition editing
sudo dnf install -y gparted

# Install easyeffects, for sound volume leveling (compression) of TV / Movies
sudo dnf install -y easyeffects

# Install 'passwords and keys' and Kgpg (GPG import / export) interfaces
sudo dnf install -y --skip-broken seahorse kgpg

# Install official google chrome (if you "enabled 3rd party repositories" during OS installation),
# AND evolution email / calendar
sudo dnf config-manager --enable google-chrome
sudo dnf install -y google-chrome-stable evolution

# Library needed for FileZilla Pro
sudo dnf install -y libxcrypt-compat

# Install virtualbox (from RPMfusion), Virtual Machine Manager, and associated tools
sudo dnf install -y --skip-broken VirtualBox virt-manager edk2-ovmf swtpm-tools spice-vdagent

# Install darkplaces-quake, steam, AND lutris
sudo dnf install -y --skip-broken darkplaces-quake darkplaces-quake-server steam lutris

# Install spotify
sudo flatpak install -y flathub com.spotify.Client

# Install cinny (Matrix chat client)
sudo flatpak install -y flathub in.cinny.Cinny

# Disable sleep mode, IF NOBODY LOGS IN VIA INTERFACE
# https://discussion.fedoraproject.org/t/gnome-suspends-after-15-minutes-of-user-inactivity-even-on-ac-power/79801
sudo -u gdm dbus-run-session gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0 > /dev/null 2>&1

# If running a geforce graphics card, install the drivers
NVIDIA_GEFORCE=$(lspci | grep -Ei 'GeForce')


    if [ "$NVIDIA_GEFORCE" != "" ]; then

    #https://discussion.fedoraproject.org/t/nvidia-drivers-with-secure-boot-no-longer-working/84444
    sudo dnf reinstall -y linux-firmware

    sleep 3

    sudo dnf install -y --skip-broken akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-libs xorg-x11-drv-nvidia-libs.i686

    sleep 3

    # https://forums.developer.nvidia.com/t/major-kde-plasma-desktop-frameskip-lag-issues-on-driver-555/293606
    # https://download.nvidia.com/XFree86/Linux-x86_64/510.60.02/README/gsp.html
    sudo grubby --update-kernel=ALL --args=nvidia.NVreg_EnableGpuFirmware=0

    fi


fi

##############################################################################
##############################################################################


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


# Update grub bootloader
sudo grub2-mkconfig -o /etc/grub2.cfg

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
echo "AFTER REBOOTING, RERUN this script with the 'sign_secureboot_modules' parameter, TO ENABLE SECURE BOOT ON ALL MODULES:"
echo "${cyan}./Fedora-Setup.bash sign_secureboot_modules"
echo "${reset} "

fi


echo " "
echo "Exiting Fedora setup..."
echo " "
