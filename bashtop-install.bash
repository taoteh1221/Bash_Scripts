#!/bin/bash

sudo apt install git

mkdir -p ~/builds

cd ~/builds

git clone https://github.com/aristocratos/bashtop.git

cd bashtop

sudo make install

echo " "
echo "bashtop installed, run 'bashtop' to load."
