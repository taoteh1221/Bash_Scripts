#!/bin/bash

MYGROUP="$USER"
sudo usermod -a -G $MYGROUP plex
sudo mkdir -p /media/$USER/Transcoding
sudo mkdir -p /media/$USER/Movies
sudo mkdir -p /media/$USER/TV
sudo chown -R $USER:$MYGROUP /media/$USER
sudo chmod 750 /media/$USER
sudo setfacl -m g:$MYGROUP:rwx /media/$USER
sudo service plexmediaserver restart
