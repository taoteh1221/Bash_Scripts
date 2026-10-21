#!/bin/bash

# proftpd sftp log MAY NOT BE ROTATED!
sudo truncate -s 0 /var/log/proftpd/sftp.log
