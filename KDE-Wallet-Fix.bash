#!/bin/bash

if [ -d ~/.gnupg/public-keys.d ]; then

cd ~/.gnupg/public-keys.d/

echo "Cleaning up any messed up session / lock file(s) left by KDEwallet..."
echo " "

# Remove lock session files SAFELY
# (BEGINS WITH PERIOD, BUT AVOIDS . AND .. DIR STRUCTURE)
rm .??* > /dev/null 2>&1

rm pubring.db.lock > /dev/null 2>&1

sleep 2

echo "Listing any existing GPG Keys..."
echo " "

gpg --list-secret-keys --keyid-format LONG

cd ~/

else

echo "Directory NOT found: ~/.gnupg/public-keys.d"

fi
