#!/bin/bash

# OVERWRITE FOR FIRST WRITE (to completely wipe any old data)
echo "'journalctl -u ifup@wlan0' output:" > ~/ipv6testing.txt

# APPEND everything else...

echo " " >> ~/ipv6testing.txt

journalctl -u ifup@wlan0 >> ~/ipv6testing.txt

sleep 1

echo " " >> ~/ipv6testing.txt

echo " " >> ~/ipv6testing.txt

echo "'ip a' output:" >> ~/ipv6testing.txt

echo " " >> ~/ipv6testing.txt

ip a >> ~/ipv6testing.txt

sleep 1

echo " " >> ~/ipv6testing.txt

echo " " >> ~/ipv6testing.txt

echo "'ip r' output:" >> ~/ipv6testing.txt

echo " " >> ~/ipv6testing.txt

ip r >> ~/ipv6testing.txt

sleep 1

echo " " >> ~/ipv6testing.txt

echo " " >> ~/ipv6testing.txt

echo "'ip -6 r' output:" >> ~/ipv6testing.txt

echo " " >> ~/ipv6testing.txt

ip -6 r >> ~/ipv6testing.txt

echo " " >> ~/ipv6testing.txt

echo " " >> ~/ipv6testing.txt


