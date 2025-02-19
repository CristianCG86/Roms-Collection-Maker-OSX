#!/bin/sh

foldergames=$1

if [ -z "$foldergames" ]; then
    echo "Usage: $0 <foldergames>"
    exit 1
fi

# Check if folder exists in ./Roms folder
if [ ! -d "./Roms/$foldergames" ]; then
    echo "Folder $foldergames does not exist in ./Roms folder"
    exit 1
fi

# Color variables
red='\033[0;31m'
clear='\033[0m'

# Variables
LOCATION="./Roms/$foldergames/"
LOCATIONROM="$LOCATION*.rom"
TARGET="./Build/EditThisList"
BANK=2
MAXFILE=0
COUNT=0
EMPTY="                                      \"leave as is\""

mkdir -p $LOCATION
mkdir -p ./Build

declare -a FBANK
FBANK[$COUNT]=$BANK

C_FILES_FOUND="$(find "$LOCATION" -maxdepth 1 -name "*.rom" | wc -l)"
if [ ${C_FILES_FOUND} -eq 0 ]; then
    echo "${red}Error: No ROMs found!${clear}"
    exit 20
fi

for i in $LOCATIONROM; do
    NAME="$(basename "$i")$EMPTY"
    FNAME[$COUNT]=$NAME
    SLOTS=$(stat -f%b "$i")
    SLOTS=$((SLOTS/16))
    FSIZE[$COUNT]=$SLOTS
    MAXFILE=$((MAXFILE+1))
    COUNT=$((COUNT+1))
    STEP=$SLOTS
    BANK=$((BANK+STEP))
    FBANK[$COUNT]=$BANK
done

if [ $BANK -gt 255 ]; then
    echo "${red}Error: ROMs exceeds 2032KB. Can not continue!${clear}"
    exit 30
fi

if [ $MAXFILE -eq 0 ]; then
    echo "${red}Error: File not found!${clear}"
    exit 40
fi

if [ -e "$TARGET.asm" ]; then
    rm "$TARGET.asm"
fi

MAXFILE=$((MAXFILE-1))
MAXLIST=0

for n in $(seq 0 $MAXFILE); do
    if [ $MAXFILE -eq $n ]; then
        MAXLIST=128
    fi
    # REMOVE EXTENSION FROM FILENAME
    GAMENAME="${FNAME[$n]%.*}                                                   "
    GAMENAME=$(echo "$GAMENAME" | tr '[:lower:]' '[:upper:]')
    echo "\tdb\t${FBANK[$n]}, ${MAXLIST}, \"     ${GAMENAME:0:35}\"" >> "$TARGET.asm"
done

EBANK=$((FBANK[$MAXFILE]+STEP))
EBANK=$((EBANK & 255))
echo "\tdb\t${EBANK}, 255, \"                                        \" ; Do not modify this line" >> "$TARGET.asm"
