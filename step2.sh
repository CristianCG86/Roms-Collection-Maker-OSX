#!/bin/sh

if [ ! -f "./Build/EditThisList.asm" ]; then
    exit
fi

cat ./Roms/*.rom > ./Build/Roms.tmp
./zasm Data2 -o ./Build/Data.tmp 2>&1 > /dev/null
cat Data1 ./Build/data.tmp ./Build/Roms.tmp > ./Build/LoadThis.rom
rm ./Build/*.tmp