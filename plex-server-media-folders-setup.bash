#!/bin/bash


# Configs

BASE_DIR="/media/taoteh1221/1tb_HDD_Disk/Plex-Videos"

USER_GROUP="$USER"


# Add user to plex group
sudo usermod -a -G $USER_GROUP plex


# Create the directory structure
sudo mkdir -p $BASE_DIR/Transcoding
sudo mkdir -p $BASE_DIR/Movies
sudo mkdir -p $BASE_DIR/TV

sleep 1

# Set permissions
sudo chown -R $USER_GROUP:$USER_GROUP $BASE_DIR
sudo chmod -R 750 $BASE_DIR
sudo setfacl -R -m g:$USER_GROUP:rwx $BASE_DIR

sleep 1

# Restart media server
sudo service plexmediaserver restart





