#!/bin/bash

sudo apt install bc -y

get_system_temp () {

temp=$(echo $(cat /sys/devices/virtual/thermal/thermal_zone0/temp) /1000 | bc)

echo "${temp}c"

}

while sleep 1; do get_system_temp; done


