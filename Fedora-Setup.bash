#!/bin/bash

PREFERRED_HOSTNAME="taoteh1221-Desktop-Asus-Lin"

SECONDS_TO_SHOW_BOOT_MENU=10

# Secure home directory from snooping
sudo chmod 750 /home/$USER

# Update PACKAGES (NOT operating system version)
sudo dnf upgrade -y

sleep 5

# Enable FUSION repos
sudo dnf install -y \
  https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

sudo dnf install -y \
  https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

sleep 5

# Refresh cache, to include the new repos
sudo dnf makecache

# Install cinnamon desktop
sudo dnf install -y @cinnamon-desktop-environment 

sleep 5

# Install dropbox for nemo (cinnamon desktop's file explorer)
sudo dnf install -y nemo-dropbox

#Install KDE
sudo dnf install -y @kde-desktop

#Install LXDE
sudo dnf group install -y lxde-desktop

# Install official google chrome (if you "enabled 3rd party repositories" during OS installation)
sudo dnf config-manager --enable google-chrome
sudo dnf install -y google-chrome-stable

# Install evolution email / calendar
sudo dnf install -y evolution

# Install preferred file archiving tools
sudo dnf install -y p7zip p7zip-plugins unrar ark engrampa

# Install preferred disk tools
sudo dnf install -y gparted

# Install samba tools
sudo dnf install -y cifs-utils

# Install cron / fire it up (will persist between reboots)
sudo dnf install -y cronie

sleep 2

sudo systemctl start crond.service

# Library needed for FileZilla Pro
sudo dnf install -y libxcrypt-compat

# Install home directory encryption tools
sudo dnf install -y ecryptfs-utils

# IOT (ARM CPU) image installer (fedora raspi images to microsd, etc)
sudo dnf install -y arm-image-installer

# Installing plugins for playing movies and music
sudo dnf group install -y Multimedia

# Install steam
sudo dnf install -y steam

# Install quake-darkplaces
sudo dnf install -y darkplaces-quake darkplaces-quake-server

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


# Update grub bootloader
sudo grub2-mkconfig -o /etc/grub2.cfg


# If running a geforce graphics card, install the drivers
NVIDIA_GEFORCE=$(lspci | grep -Ei 'GeForce')


if [ "$NVIDIA_GEFORCE" != "" ]; then

sudo dnf install -y kernel-devel kernel-headers gcc make dkms acpid libglvnd-glx libglvnd-opengl libglvnd-devel pkgconfig

sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda

fi


# FULLY lock down all ports with the firewall (already installed / activated by default in fedora),
# by changing the default zone to the included SERVER default setup
# USE WITH CAUTION, THIS EVEN LOCKS DOWN RELATED INCOMING (INITIATED BY CLIENT REQUEST LOCALLY...BROWSER, INTERNET RADIO, ETC)!!!!!
#sudo firewall-cmd --set-default-zone=FedoraServer


