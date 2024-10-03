#!/bin/bash

USER_TO_ENCRYPT_HOME_DIR="taoteh1221"

sudo authselect enable-feature with-ecryptfs

sleep 5

sudo usermod -aG ecryptfs $USER_TO_ENCRYPT_HOME_DIR

sleep 5

sudo ecryptfs-migrate-home -u $USER_TO_ENCRYPT_HOME_DIR


