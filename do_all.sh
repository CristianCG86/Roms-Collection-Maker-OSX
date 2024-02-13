#!/bin/sh

# Color variables
red='\033[0;31m'
cyan='\033[0;36m'
green='\033[0;32m'
clear='\033[0m'

echo "${cyan}Running step1.sh...${clear}"
./step1.sh
RET_CODE=$?

if [ $RET_CODE -ne 0 ]; then
    exit $RET_CODE
fi

echo "${cyan}Running step2.sh...${clear}"
./step2.sh
RET_CODE=$?

if [ $RET_CODE -ne 0 ]; then
    exit $RET_CODE
fi

echo "${green}Done!${clear}"