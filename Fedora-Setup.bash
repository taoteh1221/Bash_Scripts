#!/bin/bash

# Copyright 2024-2025 GPLv3, by Mike Kilday: Mike@DragonFrugal.com (leave this copyright / attribution intact in ALL forks / copies!)

####

# USAGE DOCUMENTATION:

####

# DOWNLOAD / RUN IT, WITH ONE COMMAND...

# wget --no-cache -O Fedora-Setup.bash https://tinyurl.com/install-fedora-setup;chmod +x Fedora-Setup.bash;./Fedora-Setup.bash

####

# "chmod +x Fedora-Setup.bash" will make this script runnable / executable

####

# "./Fedora-Setup.bash" runs this script in NORMAL setup mode

####

# "./Fedora-Setup.bash secure_minimal" runs this script in SECURE / MINIMAL setup mode

# (only installs BASIC essential packages, AND various crypto hardware wallet apps [to ~/Apps/ directory])
# for maintaining a CLEAN / SECURE MACHINE (YOU **NEVER** DO ANY REGULAR WEB SURFING / DOWNLOADING ON!! [WINK])
# (**HIGHLY CONSIDER** ENCRYPTING THE ROOT OR HOME PARTITION / DIRECTORIES ON THIS TYPE OF SETUP AS WELL!!)

# Encrypting Home Directory on Fedora (AFTER system installation):
# https://taoofmac.com/space/notes/2023/08/28/1900

# Creating Encrypted Block Devices in Anaconda (system installer interface):
# https://docs.fedoraproject.org/en-US/quick-docs/encrypting-drives-using-LUKS/#_creating_encrypted_block_devices_in_anaconda

####

# "./Fedora-Setup.bash enroll_secureboot_mok" runs this script in ENROLL MOK (Machine Owner Key) setup mode,

# for boot module signing, on secure boot enabled systems (ADDS boot module signing support)

####

# "./Fedora-Setup.bash reset_secureboot_mok" runs this script in RESET MOK (Machine Owner Key) setup mode,

# for RESETTING boot module signing, on secure boot enabled systems
# (RESETS / REMOVES boot module signing support [HELPS IF YOU HAVE MOK ISSUES, OR ARE REINSTALLING THE OS...THEN YOU CAN RE-ENROLL AFTERWARDS])

####

# "./Fedora-Setup.bash sign_secureboot_modules" runs this script in SIGN MODULES (for secure boot) setup mode,

# for boot module loading, on secure boot enabled systems (ENABLES boot module loading [in secure boot mode])
# YOU MUST WAIT, AND RUN THIS MODULE-SIGNING MODE AFTER INSTALLING DRIVERS, AND AFTER ENROLLING THE MOK KEY (BEFORE DRIVER INSTALLATION)!
# THIS IS ALSO AUTOMATICALLY RUN AT THE VERY END OF THIS SCRIPT, SO YOU WON'T NEED IT UNLESS YOU HAVE INITIAL SETUP ISSUES (LOL)

####

# "./Fedora-Setup.bash arm_image_to_device  /dev/DEVICE_NAME  https://website.address/your-disk-image.img.xz"

# Above command runs this script in ARM (xz) disk image to storage device setup mode,
# for downloading and installing an ARM disk image to a storage device (to boot an OS from that storage device [M2 drive, etc])

####


# Config

# Wifi setup (ADD SSID / PASSWORD, OR LEAVE BLANK [IF YOU DO *NOT* WANT WIFI AUTOMATICALLY SETUP!])
WIFI_SSID_SETUP=""
WIFI_PASSWORD_SETUP=""

# Hostname (set to "" to skip updating)
PREFERRED_HOSTNAME="my-hostname"

# Seconds to wait in grub, before booting up
SECONDS_TO_SHOW_BOOT_MENU=10

# Setup Cockpit remote admin?
# (SETTING TO "no" WILL *NOT* UN-INSTALL ANY EXISTING INSTALLATION)
# (Fedora SERVER edition ALREADY HAS COCKPIT INSTALLED)
SETUP_COCKPIT_REMOTE_ADMIN="no" # "no" / "yes"

# Headless setup, or NOT
# (headless setup SKIPS installing interface-related apps / libraries)
HEADLESS_SETUP_ONLY="no" # "no" / "yes"

# GROUP installs to include, during INTERFACE (*NON*-HEADLESS) setups
INTERFACE_GROUP_INSTALLS="audio 3d-printing editors games sound-and-video vlc"

# Leave BLANK "", to use host's architecture
UBOOT_DEV_BUILDS="fedora-41-aarch64"

# END Config


######################################


# Are we running on an ARM-based CPU?
IS_ARM=$(uname -r | grep "aarch64")

# Are we running a NVIDIA GEFORCE GPU?     
NVIDIA_GEFORCE=$(lspci | grep -Ei 'GeForce')

# Are we auto-selecting the NEWEST kernel, to boot by default in grub?
KERNEL_BOOTED_UPDATES=$(sudo sed -n '/UPDATEDEFAULT=yes/p' /etc/sysconfig/kernel)

ISSUES_URL="https://github.com/taoteh1221/Fedora_Setup/issues"


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


echo " "
echo "${red}PLEASE READ THE USAGE DOCUMENTATION AT THE TOP OF THIS SCRIPT'S FILE, AND CONFIGURE THE SETTINGS DIRECTLY BELOW THAT DOCUMENTATION, BEFORE RUNNING THIS SCRIPT!"
echo " "

echo "${yellow}PLEASE REPORT ANY ISSUES HERE: $ISSUES_URL${reset}"
echo " "

echo "${yellow} "
read -n1 -s -r -p $"Press Y to continue (or press N to exit)..." key
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


######################################


# Updates to grub bootloader
# (as a re-usable bash function)
setup_grub_mods() {


     # Currently, we don't support updating grub on ARM
     # (still working out if it's possible [easily enough], while remaining STABLE)
     if [ "$IS_ARM" == "" ]; then
     
     # Make grub boot menu ALWAYS SHOW (even on NON-dual-boot setups)
     sudo grub2-editenv - unset menu_auto_hide
     
     # Have grub wait 10 seconds before auto-booting
     sudo sed -i "s/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=${SECONDS_TO_SHOW_BOOT_MENU}/g" /etc/default/grub > /dev/null 2>&1
     
     # Have grub show verbose startup / shutdown screens
     # (NOT SURE FEDORA DEBUGS VERBOSE STARTUP MODE UX TOO WELL [lots of uneeded USB hub polling], BUT IT CLEARLY SHOWS WHEN ISSUES ARE HAPPENING)
     # DISABLED USING SED, AS WE CAN ACCIDENTALLY REMOVE KERNEL PARAMS WE WANT TO KEEP (LIKE NVIDIA DRIVER / NOUVEAU BLACKLISTING)!
     # sudo sed -i 's/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=""/g' /etc/default/grub > /dev/null 2>&1
     # Works in tests, as an alternate method (props to @computersavvy, thanks!):
     sudo grubby --update-kernel=ALL --remove-args="rhgb quiet"
     
     # Remove WINDOWS BOOT MANAGER from grub
     # (MODERN SECURE BOOT ENABLED setups now usually require booting windows from the UEFI boot menu hotkey at startup,
     # IF YOU HAVE A BITLOCKER-ENCRYPTED [Windows 11 Pro] windows operating system, otherwise you force-enter "recovery mode")
     OS_PROBER_CHECK=$(sudo sed -n '/GRUB_DISABLE_OS_PROBER/p' /etc/default/grub)
     
     
         if [ "$OS_PROBER_CHECK" == "" ]; then
         sudo bash -c 'echo "GRUB_DISABLE_OS_PROBER=true" >> /etc/default/grub'
         else
         sudo sed -i 's/GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=true/g' /etc/default/grub > /dev/null 2>&1
         fi
     
     
     sleep 2
     
     # Update grub bootloader
     sudo grub2-mkconfig -o /etc/grub2.cfg
     
     sleep 2
     
     elif [ "$IS_ARM" != "" ]; then
     
     echo " " > /dev/tty
     echo "${red}GRUB BOOT MODIFICATION RELATED TWEAKS ARE NOT YET (STABLY) SUPPORTED ON ARM DEVICES, SKIPPING..." > /dev/tty
     echo "${reset} " > /dev/tty
     
     fi


}


######################################


# Offer to freeze auto-selecting new kernels to boot, ON ARM DEVICES
if [ "$IS_ARM" != "" ] && [ "$KERNEL_BOOTED_UPDATES" != "" ]; then

echo "${red}Your ARM-based device is CURRENTLY setup to UPDATE the grub bootloader to boot from THE LATEST KERNEL. THIS MAY CAUSE SOME ARM-BASED DEVICES TO NOT BOOT (without MANUALLY selecting a different kernel at boot time).${reset}"

echo "${yellow} "
read -n1 -s -r -p $"PRESS F to fix this (disable grub auto-selecting NEW kernels to boot), OR any other key to skip fixing..." key
echo "${reset} "

    if [ "$key" = 'f' ] || [ "$key" = 'F' ]; then

    echo " "
    echo "${cyan}Disabling grub auto-selecting NEW kernels to boot...${reset}"
    echo " "
    
    sudo sed -i 's/UPDATEDEFAULT=.*/UPDATEDEFAULT=no/g' /etc/sysconfig/kernel > /dev/null 2>&1

    echo "${red} "
    read -n1 -s -r -p $"Press ANY KEY to REBOOT (to assure this update takes effect)..." key
    echo "${reset} "
             
             
            if [ "$key" = 'y' ] || [ "$key" != 'y' ]; then
                 
            echo " "
            echo "${green}Rebooting...${reset}"
            echo " "
                 
            sudo shutdown -r now
                 
            exit
                 
            fi
             
             
    echo " "
     
    else

    echo " "
    echo "${green}Skipping...${reset}"
    echo " "
    
    fi


fi


######################################


# Set hostname
if [ "$PREFERRED_HOSTNAME" != "" ]; then
sudo hostnamectl set-hostname $PREFERRED_HOSTNAME
fi     


# Secure user home directory, from other accounts snooping it
sudo chmod 750 /home/$USER

sleep 2

# Make sure our downloads directory exists, for TRUSTED 3rd party installs from github, etc
mkdir -p $HOME/Downloads

sleep 2

# Make sure our apps directory exists, for custom app installs to our home directory
mkdir -p $HOME/Apps

sleep 2

# Use UTC as base clock time (to avoid clock skew, on dual boot [Win11] systems)
# As user
timedatectl set-local-rtc 0
# As admin too
sudo timedatectl set-local-rtc 0

# Disable sleep mode, IF NOBODY LOGS IN VIA INTERFACE
# https://discussion.fedoraproject.org/t/gnome-suspends-after-15-minutes-of-user-inactivity-even-on-ac-power/79801
sudo -u gdm dbus-run-session gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout 0 > /dev/null 2>&1

sleep 3

# Update PACKAGES (NOT operating system version)
sudo dnf upgrade -y

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

# Install building / system tools
sudo dnf install -y --skip-broken --skip-unavailable kernel-devel-`uname -r` kernel-headers kernel-devel kernel-tools gcc make dkms acpid akmods pkgconfig elfutils-libelf-devel

# GROUP install dev tools / hardware support
sudo dnf group install -y --skip-broken --skip-unavailable c-development container-management d-development development-tools rpm-development-tools hardware-support

# Install samba / encryption / archiving tools, openssl, curl, php, flatpak, and nano
# https://discussion.fedoraproject.org/t/new-old-unrar-in-fedora-36-fails/76463
sudo dnf install -y --skip-broken --skip-unavailable cifs-utils nano ecryptfs-utils openssl curl php flatpak engrampa p7zip p7zip-plugins rar unrar

sleep 3

# Add flathub repo
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

sleep 3


# Install generic graphics card libraries, and other interface-related libraries
if [ "$HEADLESS_SETUP_ONLY" == "no" ]; then
sudo dnf install -y --skip-broken --skip-unavailable libglvnd-glx libglvnd-opengl libglvnd-devel qt5-qtx11extras
fi


sleep 3

# Install cron / fire it up (will persist between reboots)
sudo dnf install -y cronie

sleep 3

sudo systemctl start crond.service

sleep 3

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


######################################


# If we are setting up a wifi connection

WIFI_EXISTS=$(ip link show | grep -i "wlan0")

if [ "$WIFI_EXISTS" != "" ] && [ "$WIFI_SSID_SETUP" != "" ] && [ "$WIFI_PASSWORD_SETUP" != "" ]; then

sudo nmcli device wifi connect "$WIFI_SSID_SETUP" password "$WIFI_PASSWORD_SETUP"

echo " "
echo "${cyan}wifi setup has completed, UNLESS YOU SEE ANY ERRORS ABOVE."
echo "${reset} "

elif [ "$WIFI_EXISTS" == "" ]; then

echo " "
echo "${red}wifi capability was NOT found on your system, please make sure any needed firmware (for your wifi chip) has been installed."
echo "${reset} "

fi


######################################


# If we are doing a secure / minimal setup, install / tweak some stuff, and EXIT setup early
if [ "$1" == "secure_minimal" ]; then

     
     # If NOT a headless setup, install web browsers / email, and various crypto hardware wallet apps
     if [ "$HEADLESS_SETUP_ONLY" == "no" ]; then
     
     # Install official google chrome (if you "enabled 3rd party repositories" during OS installation),
     # chromium, AND evolution email / calendar
     sudo dnf config-manager --enable google-chrome
     sudo dnf install -y --skip-broken --skip-unavailable google-chrome-stable chromium evolution
          
     # Install crypto wallet apps, from TRUSTED 3rd party download locations...
     
     echo " "
     echo "${cyan}Installing various crypto hardware wallet apps to ${HOME}/Apps, please wait..."
     echo "${reset} "
     
     # Ledger crypto hardware wallet linux permissions
     wget -q -O - https://raw.githubusercontent.com/LedgerHQ/udev-rules/master/add_udev_rules.sh | sudo bash
     
     # Ledger Live app
     mkdir -p $HOME/Apps/Ledger-Live
     
     sleep 2
     
     cd $HOME/Apps/Ledger-Live
     
     # NO ARM SUPPORT
     wget --no-cache -O ledger-live.AppImage https://download.live.ledger.com/latest/linux
     
     sleep 2
     
     chmod +x ledger-live.AppImage
     
     # Trezor crypto hardware wallet linux permissions
     sudo curl https://data.trezor.io/udev/51-trezor.rules -o /etc/udev/rules.d/51-trezor.rules
     
     # Trezor app
     mkdir -p $HOME/Apps/Trezor
     
     sleep 2
     
     cd $HOME/Apps/Trezor
     
     
     if [ "$IS_ARM" == "" ]; then
     
     wget --no-cache -O trezor-app.AppImage https://github.com/trezor/trezor-suite/releases/download/v25.1.2/Trezor-Suite-25.1.2-linux-x86_64.AppImage
     
     else
     
     wget --no-cache -O trezor-app.AppImage https://github.com/trezor/trezor-suite/releases/download/v25.1.2/Trezor-Suite-25.1.2-linux-arm64.AppImage
     
     fi
     
     
     sleep 2
     
     chmod +x trezor-app.AppImage
     
     fi


cd ${HOME}

# Grub mods
setup_grub_mods

echo " "

echo "${red}**HIGHLY CONSIDER** ENCRYPTING THE ROOT OR HOME PARTITION / DIRECTORIES ON THIS TYPE OF SETUP AS WELL!!"
echo "${reset} "

echo "${yellow}Encrypting Home Directory on Fedora (AFTER system installation):"
echo "${cyan}https://taoofmac.com/space/notes/2023/08/28/1900"
echo "${reset} "

echo "${yellow}Creating Encrypted Block Devices in Anaconda (system installer interface):"
echo "${cyan}https://docs.fedoraproject.org/en-US/quick-docs/encrypting-drives-using-LUKS/#_creating_encrypted_block_devices_in_anaconda"
echo "${reset} "

echo "${cyan}Secure / minimal setup mode has completed, exiting Fedora setup..."
echo "${reset} "

exit

fi


######################################


# Install an ARM disk image to a storage device (UNTESTED!)
if [ "$IS_ARM" != "" ] && [ "$1" == "arm_image_to_device" ] && [ "$2" != "" ] && [ "$3" != "" ]; then

URL_STATUS=$(curl --head --silent --write-out "%{http_code}" --output /dev/null ${3})

ALREADY_MOUNTED=$(findmnt | grep "${2}")


    if [ -f "$2" ] && [ "$ALREADY_MOUNTED" == "" ] && [ $URL_STATUS -eq 200 ]; then

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
    
    # Flush disk cache
    sync
    
    sleep 5
    
    PART_COUNT=$(sudo partx -g ${2} | wc -l)
    
    echo " "
    echo "${cyan}XZ disk image finished writing to device '${2}', EXPANDING partition ${2}${PART_COUNT} (to use ENTIRE physical storage space), please wait..."
    echo "${reset} "
    
    # https://unix.stackexchange.com/a/761845/390828
    sudo parted ${2} print free
    
    sleep 5
    
    sudo parted ${2} resizepart ${PART_COUNT} 100%
    
    sleep 5

    sudo e2fsck -f ${2}${PART_COUNT}
    
    sleep 5

    sudo resize2fs ${2}${PART_COUNT}
    
    sleep 5
    
    echo " "
    echo "${cyan}EXPANDING of partition ${2}${PART_COUNT} has completed."
    echo "${reset} "

    elif [ ! -f "$2" ]; then

    echo " "
    echo "${red}Device '${2}' does NOT exist."
    echo "${reset} "

    elif [ "$ALREADY_MOUNTED" != "" ]; then

    echo " "
    echo "${red}Device '${2}' is already mounted."
    echo "${reset} "

    elif [ $URL_STATUS -ne 200 ]; then

    echo " "
    echo "${red}XZ disk image parameter MUST BE a web link, your entered web link address '${3}' returned an error code: ${URL_STATUS}"
    echo "${reset} "

    fi


exit

elif [ "$IS_ARM" == "" ] && [ "$1" == "arm_image_to_device" ]; then

echo " "
echo "${red}Your system does NOT appear to be ARM-based."
echo "${reset} "

exit

elif [ "$2" == "" ] && [ "$1" == "arm_image_to_device" ]; then

echo " "
echo "${red}Device parameter was NOT included."
echo "${reset} "

exit

elif [ "$3" == "" ] && [ "$1" == "arm_image_to_device" ]; then

echo " "
echo "${red}XZ disk image parameter was NOT included."
echo "${reset} "

exit

fi


######################################


# If we are DELETING a MOK (Machine Owner Key), for secure boot module signing
# /usr/share/doc/akmods/README.secureboot
if [ "$IS_ARM" == "" ] && [ "$1" == "reset_secureboot_mok" ]; then

echo " "
echo "${yellow}Create a PIN to enter, which you will need after you reboot your computer, to REMOVE your MOK (Machine Owner Key):"
echo "${reset} "

sudo mokutil --reset

echo " "
echo "Exiting MOK reset..."
echo " "

echo " "
echo "${red}YOU MUST NOW REBOOT YOUR COMPUTER, INITIATE 'MOK Management', CHOOSE 'Reset MOK / Yes' -> 'Continue / Reboot', ENTER THE PIN YOU CREATED / REBOOT, to remove MOK module signing!"
echo "${reset} "

echo "${red} "
read -n1 -s -r -p $"Press Y to REBOOT (or press N to exit this script)..." key
echo "${reset} "
        
        
       if [ "$key" = 'y' ] || [ "$key" = 'Y' ]; then
            
       echo " "
       echo "${green}Rebooting...${reset}"
       echo " "
            
       sudo shutdown -r now
            
       else
            
       echo " "
       echo "${green}Exiting...${reset}"
       echo " "
            
       exit
            
       fi
        
        
echo " "
        
exit

# If we are CREATING a MOK (Machine Owner Key), for secure boot module signing
# /usr/share/doc/akmods/README.secureboot
elif [ "$IS_ARM" == "" ] && [ "$1" == "enroll_secureboot_mok" ]; then

    
     # Check to see if MOK keys have already been setup
     if sudo [ ! -f "/etc/pki/akmods/certs/public_key.der" ]; then

     echo " "
     echo "${cyan}Creating a MOK (Machine Owner Key) security certificate, PLEASE FILL IN DETAILS BELOW, WHEN ASKED:"
     echo "${reset} "

     sudo kmodgenca
     
     sleep 3

     fi


echo " "
echo "${yellow}Create a PIN to enter, which you will need after you reboot your computer (CONSIDER WRITING IT DOWN, SO YOU DON'T FORGET), to ENROLL your MOK (Machine Owner Key), for secure boot module signing:"
echo "${reset} "

sudo mokutil --import /etc/pki/akmods/certs/public_key.der

echo " "
echo "${cyan}Finished MOK setup..."
echo "${reset} "

echo " "
echo "${red}YOU *MUST* NOW REBOOT YOUR COMPUTER, INITIATE 'MOK Management', CHOOSE 'Enroll MOK' -> 'Continue', ENTER THE PIN YOU CREATED / REBOOT, to enable MOK module signing!"
echo "AFTER REBOOTING, RERUN this script, TO INSTALL / ENABLE SECURE BOOT MODULES (VIRTUALBOX / NVIDIA, ETC):"
echo "${cyan}./Fedora-Setup.bash sign_secureboot_modules"
echo "${reset} "

echo "${red} "
read -n1 -s -r -p $"Press Y to REBOOT (or press N to exit this script)..." key
echo "${reset} "
        
        
       if [ "$key" = 'y' ] || [ "$key" = 'Y' ]; then
            
       echo " "
       echo "${green}Rebooting...${reset}"
       echo " "
            
       sudo shutdown -r now
            
       else
            
       echo " "
       echo "${green}Exiting...${reset}"
       echo " "
            
       exit
            
       fi
        
        
echo " "
        
exit

# Sign secure boot modules
elif [ "$IS_ARM" == "" ] && [ "$1" == "sign_secureboot_modules" ]; then

sudo akmods --force --rebuild

echo " "
echo "Finished module-signing setup..."
echo " "

echo " "
echo "${red}REBOOT YOUR MACHINE ONE LAST TIME, TO ALLOW LOADING ALL MODULES IN SECURE BOOT MODE."
echo "${reset} "

echo "${red} "
read -n1 -s -r -p $"Press Y to REBOOT (or press N to exit this script)..." key
echo "${reset} "
        
        
       if [ "$key" = 'y' ] || [ "$key" = 'Y' ]; then
            
       echo " "
       echo "${green}Rebooting...${reset}"
       echo " "
            
       sudo shutdown -r now
            
       else
            
       echo " "
       echo "${green}Exiting...${reset}"
       echo " "
            
       exit
            
       fi
        
        
echo " "
        
exit

elif [ "$IS_ARM" != "" ] && [ "$1" == "sign_secureboot_modules" ]; then

echo " "
echo "${red}SECURE BOOT MODULE SETUP ON ARM DEVICES IS NOT CURRENTLY SUPPORTED BY THIS SCRIPT, EXITING..."
echo "${reset} "

exit

fi
# END secure boot modules setup


######################################


# Check to see if MOK secure boot module signing KEYS have already been setup
# /usr/share/doc/akmods/README.secureboot
if [ "$IS_ARM" == "" ] && sudo [ ! -f "/etc/pki/akmods/certs/public_key.der" ]; then

echo " "
echo "${red}MOK (Machine Owner Key) secure boot module signing has NOT been setup yet, RERUN this script with the 'enroll_secureboot_mok' parameter:"
echo "${cyan}./Fedora-Setup.bash enroll_secureboot_mok"
echo "${reset} "
echo "Exiting Fedora setup..."
echo " "

# EXIT
exit

fi


######################################


# If we are enabling cockpit, for remote admin UI ability
if [ "$SETUP_COCKPIT_REMOTE_ADMIN" == "yes" ]; then

sudo dnf install -y cockpit

sleep 3

sudo systemctl enable --now cockpit.socket

sudo firewall-cmd --add-service=cockpit

sudo firewall-cmd --add-service=cockpit --permanent

fi


# Install uboot tools (for making ARM disk images bootable)
sudo dnf install -y --skip-broken --skip-unavailable uboot-tools uboot-images-armv8 rkdeveloptool gdisk

# IOT (ARM CPU) image installer (fedora raspi / radxa / other images to microsd, etc), AND enable 'updates-testing' repo
# https://fedoraproject.org/wiki/Architectures/ARM/Installation#Arm_Image_Installer
# All board ids (filenames) in /usr/share/arm-image-installer/boards.d/ are the available
# (fully supported) "target" parameter values for disk writing uboot automatically to same storage as the rootfs image
# Headless setup w/ wifi:
# https://www.redhat.com/en/blog/fedora-iot-raspberry-pi
sudo dnf install --enablerepo=updates-testing -y arm-image-installer

# Add repo to have various FEDORA-COMPATIBLE uboot images
# (LAST PARAMETER IS OPTIONAL [OR REQUIRED, IF INSTALLED ON A DIFFERENT DEVICE WITHOUT A MATCHING ARCHITECTURE])
sudo dnf copr enable -y pbrobinson/u-boot $UBOOT_DEV_BUILDS

# Get Fedora uboot images (are stored in: /usr/share/uboot/), for device flashing
sudo dnf install -y uboot-images-copr

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
# IMPORTANT NOTE:
# Rock5b devices WILL NOT SUPPORT HDMI DISPLAY OUTPUT UNTIL LINUX KERNEL v6.13, SO ONBOARD SPI FLASH CAN ONLY BE DONE FLYING BLIND (GOOD LUCK, I GAVE UP)
# MORE RELEVANT ROCK5B SETUP NOTES ARE HERE:
# https://yrzr.github.io/notes-build-uboot-for-rock5b/#3-collabora-u-boot-mainline
####
# Raspi Hat setup:
# https://fedoraproject.org/w/index.php?title=Architectures/ARM/Raspberry_Pi/HATs


##############################################################################
##############################################################################


# If we are doing a graphical interface setup (NOT headless / terminal-only)
if [ "$HEADLESS_SETUP_ONLY" == "no" ]; then


     # GROUP INSTALLS for games / media support / etc
     if [ "$INTERFACE_GROUP_INSTALLS" != "" ]; then
     sudo dnf group install -y --skip-broken --skip-unavailable $INTERFACE_GROUP_INSTALLS
     fi

     
     # DESKTOP INTERFACING / VIRTUAL MACHINE SUPPORT...
     
     # FOR NON-ARM DEVICES
     if [ "$IS_ARM" == "" ]; then
     
     # Install cinnamon desktop (NO KNOWN ISSUES ON X86 'WORKSTATION' VERSION OF FEDORA)
     sudo dnf install -y --skip-broken --skip-unavailable @cinnamon-desktop-environment nemo-dropbox
     
     # Install KDE...DISABLED FOR NOW, MAY HAVE QA ISSUES ON FEDORA?
     # (whole system got borked HARD running it daily for a couple weeks w/ NVIDIA 3070,
     # FOR FIRST HEAVY DAILY USAGE EVER, AND USING THEIR SYSTEM UPDATER..IDK
     # [ALSO HAD A POWERED USB HUB GETTING PROBED / HINDERING SYSTEM STARTUP...YIKES])
     #sudo dnf install -y --skip-broken --skip-unavailable @kde-desktop dolphin-plugins
     
     # Install official google chrome (if you "enabled 3rd party repositories" during OS installation),
     # AND evolution email / calendar
     sudo dnf config-manager --enable google-chrome
     sudo dnf install -y --skip-broken --skip-unavailable google-chrome-stable evolution
     
     # Install virtualbox (from RPMfusion), Virtual Machine Manager, and associated tools
     sudo dnf install -y --skip-broken --skip-unavailable VirtualBox virt-manager edk2-ovmf swtpm-tools spice-vdagent
     
     sleep 5
     
     # Kernel 6.12 in F41 breaks virtualbox support, fixable with kernel boot params:
     # https://www.reddit.com/r/linuxquestions/comments/1hh9k21/virtualbox_broken_after_kernel_612_fedora_41/
     sudo grubby --update-kernel=DEFAULT --args="kvm.enable_virt_at_load=0"
     
         
         # If running a geforce graphics card, install the drivers / system monitor
         # https://rpmfusion.org/Howto/NVIDIA#Switching_between_nouveau.2Fnvidia
         if [ "$NVIDIA_GEFORCE" != "" ]; then
     
         #https://discussion.fedoraproject.org/t/nvidia-drivers-with-secure-boot-no-longer-working/84444
         # (IF YOU BORK UP A NVIDIA UNINSTALL)
         #sudo dnf reinstall -y linux-firmware
     
         sleep 3
     
         sudo dnf install -y --skip-broken --skip-unavailable akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-libs xorg-x11-drv-nvidia-libs.i686
     
         sleep 3
         
         # NVIDIA System monitor
         sudo flatpak install -y flathub io.github.congard.qnvsm     
     
         # https://forums.developer.nvidia.com/t/major-kde-plasma-desktop-frameskip-lag-issues-on-driver-555/293606
         # https://download.nvidia.com/XFree86/Linux-x86_64/510.60.02/README/gsp.html
         # IF YOU USE KDE?! IDK
         #sudo grubby --update-kernel=ALL --args=nvidia.NVreg_EnableGpuFirmware=0
     
         fi
    
    
     # FOR ARM DEVICES
     elif [ "$IS_ARM" != "" ]; then
     
     # Install AND ENABLE LIGHTDM / LXDE DESKTOP
     
     # REGULAR install
     sudo dnf install -y lightdm

     sleep 5     
     
     # GROUP install
     sudo dnf group install -y lxde-desktop
     
     sleep 5
     
     # DISABLE gdm at boot
     sudo systemctl disable gdm.service
     
     sleep 5
     
     # ENABLE lightdm at boot
     # DEBUG: sudo lightdm –-test-mode --debug
     # DEBUG: journalctl -b -u lightdm.service
     sudo systemctl enable lightdm.service
     
     # Install chromium, AND evolution email / calendar
     sudo dnf install -y --skip-broken --skip-unavailable chromium evolution
     
     fi


# Install gparted, for partition editing, and Fedora USB disk image creator
sudo dnf install --skip-broken --skip-unavailable -y gparted liveusb-creator

# Install easyeffects, for sound volume leveling (compression) of TV / Movies
sudo dnf install -y easyeffects

# Install 'passwords and keys' and kleopatra (GPG import / export)
sudo dnf install -y --skip-broken --skip-unavailable seahorse kleopatra

# Install bluefish, filezilla, meld, gimp, and library needed for FileZilla Pro
sudo dnf install -y --skip-broken --skip-unavailable bluefish filezilla meld gimp libxcrypt-compat

# Add official LINUX Github Desktop repo, and install it
sudo rpm --import https://rpm.packages.shiftkey.dev/gpg.key

sudo sh -c 'echo -e "[shiftkey-packages]\nname=GitHub Desktop\nbaseurl=https://rpm.packages.shiftkey.dev/rpm/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://rpm.packages.shiftkey.dev/gpg.key" > /etc/yum.repos.d/shiftkey-packages.repo'

# No ARM support
sudo dnf install -y github-desktop

# Install darkplaces-quake, steam, AND lutris
sudo dnf install -y --skip-broken --skip-unavailable darkplaces-quake darkplaces-quake-server steam lutris

sleep 3

mkdir -p $HOME/Apps/Quake-Darkplaces

sleep 2

ln -s /usr/bin/darkplaces-quake-sdl $HOME/Apps/Quake-Darkplaces/darkplaces-quake-sdl

ln -s /usr/bin/darkplaces-quake-glx $HOME/Apps/Quake-Darkplaces/darkplaces-quake-glx

# Install flatpaks, AFTER video drivers (so any proper video dependencies are installed)

# Install spotify
sudo flatpak install -y flathub com.spotify.Client

# Install Element (Matrix chat client)
sudo flatpak install -y flathub im.riot.Riot

# Install Plex (streaming video client)
sudo flatpak install -y flathub tv.plex.PlexDesktop

# Install Discord (social channels client)
sudo flatpak install -y flathub com.discordapp.Discord

# Install Telegram (social channels client)
sudo flatpak install -y flathub org.telegram.desktop

# Install Zoom (video chat client)
sudo flatpak install -y flathub us.zoom.Zoom

# Install from TRUSTED 3rd party download locations
cd ${HOME}/Downloads


     # Balena Etcher
     if [ "$IS_ARM" == "" ]; then
     
     wget --no-cache -O balena-etcher.rpm https://github.com/balena-io/etcher/releases/download/v1.19.25/balena-etcher-1.19.25-1.x86_64.rpm
     
     else
     
     wget --no-cache -O balena-etcher.rpm https://github.com/Itai-Nelken/BalenaEtcher-arm/releases/download/v1.7.9/balena-etcher-electron-1.7.9+5945ab1f.aarch64.rpm
     
     fi


cd ${HOME}

sleep 2

sudo dnf install -y ${HOME}/Downloads/balena-etcher.rpm

fi


##############################################################################
##############################################################################


# If NOT ARM, RUN SOME BOOT-RELATED LOGIC / NOTICES
if [ "$IS_ARM" == "" ]; then

# Grub mods
setup_grub_mods

# Rebuild any nvidia / virtualbox / etc boot modules, and sign them with the appropriate MOK
sudo akmods --force --rebuild


    if [ ! -f "${HOME}/.fedora_setup_1st_run.dat" ]; then


        # If running a geforce graphics card
        if [ "$NVIDIA_GEFORCE" != "" ]; then
    
        echo " "
        echo "${red}ALWAYS USE FEDORA'S BUNDLED GEFORCE DRIVERS, AS THE MANUFACTURER-SUPPLIED DRIVERS ARE DISTRO-AGNOSTIC (NOT TAILORED SPECIFICALLY TO FEDORA), AND CAN CAUSE ISSUES!"

        echo " "
        echo "ADDITIONALLY, ALWAYS WAIT 10-15 MINUTES AFTER NVIDIA DRIVERS HAVE BEEN INSTALLED, BEFORE REBOOT / SHUTDOWN, AS SOMETIMES THE BOOT MODULES ARE STILL BEING BUILT SILENTLY IN THE BACKGROUND (NOT SURE WHY THIS UX IS SO HORRIBLE, BUT IT IS!)"

        fi

    
    echo " "
    echo "MORE INFO IS HERE, RELATED TO RUNNING BOOT MODULES IN SECURE BOOT MODE:"
    echo "${cyan}https://fedoraproject.org/wiki/Changes/NvidiaInstallationWithSecureboot"
    echo "/usr/share/doc/akmods/README.secureboot"
    echo "${reset} "

    echo -e "ran" > ${HOME}/.fedora_setup_1st_run.dat

    fi
    
    
fi


# FULLY lock down all ports with the firewall (already installed / activated by default in fedora),
# by changing the default zone to the included SERVER default setup
# USE WITH CAUTION, THIS EVEN LOCKS DOWN RELATED INCOMING (INITIATED BY CLIENT REQUEST LOCALLY...BROWSER, INTERNET RADIO, ETC)!!!!!
#sudo firewall-cmd --set-default-zone=FedoraServer

echo " "
echo "${cyan}Fedora setup has fully completed, exiting..."
echo "${reset} "

exit


