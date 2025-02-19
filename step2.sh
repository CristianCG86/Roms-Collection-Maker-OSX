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

if [ ! -f "./Build/EditThisList.asm" ]; then
    exit
fi

cat ./Roms/$foldergames/*.rom > ./Build/Roms.tmp
./zasm -w "RCM Menu v2.asm" "RCM Menu.bin"
cat "RCM Menu.bin" ./Build/Roms.tmp > ./Build/LoadThis.rom
rm ./Build/*.tmp
rm "RCM Menu.bin"
rm "RCM Menu.lst"