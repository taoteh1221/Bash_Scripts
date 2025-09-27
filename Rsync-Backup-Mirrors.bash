#!/bin/bash

# Copyright 2025 GPLv3, By Mike Kilday: Mike@DragonFrugal.com (leave this copyright / attribution intact in ALL forks / copies!)


# CONFIG - START #########################################


# NAS backups (mounted) location
NAS_BACKUPS="/mnt/NAS_Private/Backups"


# Mirror for local-only files to backup to (files / dirs in user home dir)
LOCAL_ONLY_MIRROR="/mnt/NAS_Private/Backups/Local_Only"


# Secondary drive (on this PC)
SECONDARY_DRIVE="/mnt/4tb_hdd"


# CONFIG - END #########################################


dir_mirror() {

     if [ ! -z "$1" ] && [ ! -z "$2" ] && [ -d "$1" ] && [ -d "$2" ]; then
     # exclude .desktop files / .git folders / symbolic links, AND delete when target non-existent in source
     rsync -rtvpl --exclude='*.desktop' --exclude='/.git' --no-links --delete $1 $2 > /dev/tty
     else
     echo " " > /dev/tty
     echo "SOURCE (${1}) and DESTINATION (${2}) paths MUST be included, and both must EXIST already" > /dev/tty
     echo " " > /dev/tty
     fi
     
}


gzip_archive() {

     if [ ! -z "$1" ] && [ ! -z "$2" ] && [ -d "$1" ]; then
     
     # excluding .git folders
     tar czf $2 --overwrite --exclude ".git" $1 > /dev/tty

     # Pause 1 second, in case we are about to mirror any directory we archived into
     sleep 1

     else
     echo " " > /dev/tty
     echo "SOURCE (${1}) and DESTINATION (${2}) paths MUST be included, and source must EXIST already" > /dev/tty
     echo " " > /dev/tty
     fi
     
}


########### A R C H I V I N G ######################################


# Gzip DEVELOPING to BACKUPS
gzip_archive ~/Developing ~/Backups/Developing.tar.gz


# Gzip DOCUMENTS to BACKUPS
gzip_archive ~/Documents ~/Backups/Documents.tar.gz


# Gzip APPS to BACKUPS
gzip_archive ~/Apps ~/Backups/Apps.tar.gz


########### M I R R O R I N G ######################################


# Mirror BACKUPS to NAS LOCAL ONLY Backups
dir_mirror ~/Backups $LOCAL_ONLY_MIRROR


# Mirror DESKTOP to NAS LOCAL ONLY Backups
dir_mirror ~/Desktop $LOCAL_ONLY_MIRROR


# Mirror DOWNLOADS to NAS LOCAL ONLY Backups
dir_mirror ~/Downloads $LOCAL_ONLY_MIRROR


# Mirror DROPBOX to NAS LOCAL ONLY Backups
dir_mirror ~/Dropbox $LOCAL_ONLY_MIRROR


# Mirror MUSIC to NAS LOCAL ONLY Backups
dir_mirror ~/Music $LOCAL_ONLY_MIRROR


# Mirror PICTURES to NAS LOCAL ONLY Backups
dir_mirror ~/Pictures $LOCAL_ONLY_MIRROR


# Mirror SCRIPTS to NAS LOCAL ONLY Backups
dir_mirror ~/Scripts $LOCAL_ONLY_MIRROR


# Mirror VIDEOS to NAS LOCAL ONLY Backups
dir_mirror ~/Videos $LOCAL_ONLY_MIRROR


# Mirror ALL NAS Backups to Secondary drive on this PC
dir_mirror $NAS_BACKUPS $SECONDARY_DRIVE



############# E N D #################


echo " "
read -n1 -s -r -p $"Archiving and rsync mirroring completed, press any key to exit..." key
echo " "



