#!/bin/bash

# USAGE:
# "./Fix.ntfs.bash /dev/PARTITION_ID_HERE"

sudo dnf install -y ntfsprogs

sleep 3

sudo umount "$1"

sleep 3

sudo ntfsfix "$1"
