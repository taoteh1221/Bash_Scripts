#!/bin/bash

# Copyright 2026 GPLv3, by Mike Kilday: Mike@DragonFrugal.com (leave this copyright / attribution intact in ALL forks / copies!)

####

# USAGE DOCUMENTATION:

####

# "./Git-Squash-ALL-Repo-Commits /path/to/local/repo/" runs the

## squash commit on any repo at this location

####

######################################

# https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux

if hash tput > /dev/null 2>&1; then

red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`

reset=`tput sgr0`

else

red=``
green=``
yellow=``
blue=``
magenta=``
cyan=``

reset=``

fi

######################################


if [ ! -z "$1" ] && [ "$1" != "" ] && [ -d $1 ]; then
GIT_DIR_PATH=$1
else
echo " "
echo "${red}'${1}' Is NOT a directory, exiting...${reset}"
echo " "
exit
fi


echo " "
echo "${red}Proceed with squashing the ENTIRE git commit history into a single squashing commit, for the git repository in the directory?"
echo "${GIT_DIR_PATH}"
echo " "

echo "${yellow} "
read -n1 -s -r -p $"Press Y to continue squashing all commits for this repo (or press N to exit)..." key
echo "${reset} "

    if [ "$key" = 'y' ] || [ "$key" = 'Y' ]; then

    echo " "
    echo "${green}Continuing with squashing commits...${reset}"
    echo " "
    
    cd $GIT_DIR_PATH

    sleep 1

    git reset $(git commit-tree HEAD^{tree} -m "Commits squash")
    
    sleep 1
    
    cd ~/

    echo " "
    echo "${green}ALL previous commits have been squashed in: ${GIT_DIR_PATH}${reset}"
    echo " "

    else
    echo " "
    echo "${green}Skipped squashing commits...${reset}"
    echo " "
    exit
    fi

echo " "


