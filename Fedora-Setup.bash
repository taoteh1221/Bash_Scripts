#/bin/bash

# Install cinnamon desktop
sudo dnf install @cinnamon-desktop-environment 

#Install KDE
sudo dnf install @kde-desktop

# Install official google chrome (if you "enabled 3rd party repositories" during OS installation)
sudo dnf config-manager --enable google-chrome
sudo dnf install google-chrome-stable

# Install preferred file archiving tools
sudo dnf install p7zip p7zip-plugins unrar ark engrampa

# Install home directory encryption tools
sudo dnf install ecryptfs-utils

# Install quake-darkplaces
sudo dnf install quake-darkplaces

# Make grub boot menu ALWAYS SHOW (even on NON-dual-boot setups)
sudo grub2-editenv - unset menu_auto_hide

# Set hostname
sudo hostnamectl set-hostname new-name

# Have grub wait 10 seconds before auto-booting
sudo sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=10/g' /etc/default/grub > /dev/null 2>&1

# Have grub show verbose startup / shutdown screens
sudo sed -i 's/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX=""/g' /etc/default/grub > /dev/null 2>&1

# Update grub bootloader
sudo grub2-mkconfig -o /etc/grub2.cfg

# FULLY lock down all ports with the firewall (already installed / activated by default in fedora),
# by changing the default zone to the included SERVER default setup
# USE WITH CAUTION, THIS EVEN LOCKS DOWN RELATED INCOMING (INITIATED BY CLIENT REQUEST LOCALLY...BROWSER, INTERNET RADIO, ETC)!!!!!
#sudo firewall-cmd --set-default-zone=FedoraServer


