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

if [ ! -f "./src/RomList.asm" ]; then
    echo "File RomList.asm does not exist in ./src folder"
    exit
fi

cat ./Roms/$foldergames/*.rom > ./Build/Roms.tmp
./zasm -w "./src/RCM Menu v2.asm" "./Build/RCM Menu.bin"
cat "./Build/RCM Menu.bin" ./Build/Roms.tmp > ./Build/LoadThis.rom
rm ./Build/*.tmp
rm "./Build/RCM Menu.bin"
rm "./Build/RCM Menu v2.lst"