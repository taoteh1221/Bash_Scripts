#!/bin/bash

sudo apt install gcc libc-dev -y

wget https://raw.githubusercontent.com/ssvb/cpuburn-arm/master/cpuburn-a53.S

gcc -o cpuburn-a53 cpuburn-a53.S

./cpuburn-a53
