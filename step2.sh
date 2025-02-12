#!/bin/sh

if [ ! -f "./Build/EditThisList.asm" ]; then
    exit
fi

cat ./Roms/KONAMICLASSIC/*.rom > ./Build/Roms.tmp
./zasm -w "RCM Menu v2.asm" "RCM Menu.bin"
cat "RCM Menu.bin" ./Build/Roms.tmp > ./Build/LoadThis.rom
rm ./Build/*.tmp
rm "RCM Menu.bin"
rm "RCM Menu.lst"