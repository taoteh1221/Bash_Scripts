#!/bin/bash


########################################################################################################################
########################################################################################################################

# Copyright 2022-2023 GPLv3, By Mike Kilday: Mike@DragonFrugal.com

# https://github.com/taoteh1221/Bash_Scripts (pdf-merge.bash)

# CREDIT: https://stackoverflow.com/questions/68010034/how-can-i-merge-pdf-files-together-and-take-only-the-first-page-from-each-file

# DON'T FORGET TO MAKE THIS SCRIPT EXECUTABLE: chmod +x pdf-merge.bash

# A command line parameter can be passed to auto-select menu choices. Multi sub-option selecting is available too,
# by seperating each sub-option with a space, AND ecapsulating everything in quotes like "option1 sub-option2 sub-sub-option3".

# Running normally (displays options to choose from):

# ./pdf-merge.bash
 
# Auto-selecting single / multi sub-option examples (MULTI SUB-OPTIONS #MUST# BE IN QUOTES!):
 
# ./pdf-merge.bash "/path/to/pdf/files 1"
# (merges FIRST PAGE of every PDF file in the directory, into qpdf_combined_docs_[DATE].pdf)

# ./pdf-merge.bash "/path/to/pdf/files all"
# (merges ALL PAGES of every PDF file in the directory, into qpdf_combined_docs_[DATE].pdf)

########################################################################################################################
########################################################################################################################


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


# Get primary dependency apps, if we haven't yet
    
# Install qpdf if needed
QPDF_PATH=$(which qpdf)

if [ -z "$QPDF_PATH" ]; then

echo " "
echo "${cyan}Installing required component qpdf, please wait...${reset}"
echo " "

sudo apt update

sudo apt install qpdf -y

fi


######################################


# Get date / time
DATE=$(date '+%Y-%m-%d')
TIME=$(date '+%H:%M:%S')


# If a symlink, get link target for script location
 # WE ALWAYS WANT THE FULL PATH!
if [[ -L "$0" ]]; then
SCRIPT_LOCATION=$(readlink "$0")
else
SCRIPT_LOCATION="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )/"$(basename "$0")""
fi

# Now set path / file vars, after setting SCRIPT_LOCATION
SCRIPT_PATH="$( cd -- "$(dirname "$SCRIPT_LOCATION")" >/dev/null 2>&1 ; pwd -P )"
SCRIPT_NAME=$(basename "$SCRIPT_LOCATION")


######################################


# If parameters are added via command line
# (CLEANEST WAY TO RUN PARAMETER INPUT #TO AUTO-SELECT MULTIPLE CONSECUTIVE OPTION MENUS#)
# (WE CAN PASS THEM #IN QUOTES# AS: command "option1 sub-option2 sub-sub-option3")
if [ "$1" != "" ] && [ "$APP_RECURSE" != "1" ]; then
APP_RECURSE=1
export APP_RECURSE=$APP_RECURSE
printf "%s\n" $1 | "$SCRIPT_LOCATION"
exit
fi


######################################

			
echo " "
echo "${yellow}Enter the FULL SYSTEM PATH to the PDF directory:"
echo " "

read PDF_DIR
echo " "
        
if [ -z "$PDF_DIR" ]; then
echo "${red}No PDF directory set, exiting..."
echo "${reset}"
exit
else
echo "${green}Using PDF directory:"
echo "$PDF_DIR${reset}"
fi

echo " "

if [ ! -d "$PDF_DIR" ]; then
echo "The defined PDF directory '$PDF_DIR' does not exist yet."
echo "Please create this directory structure before running this script."
echo "Exiting..."
exit
fi


######################################

			
echo "${yellow}How many pages should be merged from each PDF document:"
echo "(enter 'all' to included every page)"
echo " "

read INC_PAGES
echo " "

cd $PDF_DIR

# Remove any previous combined docs file
rm qpdf_combined_docs_$DATE.pdf > /dev/null 2>&1

if [ "$INC_PAGES" != "all" ]; then
qpdf --empty --pages $(for i in *.pdf; do echo $i $INC_PAGES; done) -- qpdf_combined_docs_$DATE.pdf
else
qpdf --empty --pages $(for i in *.pdf; do echo $i; done) -- qpdf_combined_docs_$DATE.pdf
fi

echo "${green}PDF documents in ${PDF_DIR} have been combined (${INC_PAGES} pages from each document), into this file:"
echo " "
echo "${PDF_DIR}qpdf_combined_docs_$DATE.pdf${reset}"
echo " "


######################################

			
		
