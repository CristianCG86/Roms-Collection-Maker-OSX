## Description

This tool for Mac OSX is used to facilitate the creation of ROM compilations for the [Flash ROM SCC cartridge](https://www.msx.org/wiki/Popolon-fr_Flash-ROM_SCC_Cartridge) with a simple menu to run them. It consists of a set of BATCH scripts and external executables.

Is an adaptation of popolon-fr code. [GitHub](https://github.com/popolonfr/Roms-Collection-Maker)

## Download the files

It is not necessary to download anything. The zasm version is already included.

## Prepare files

You will have to give execution rights to the scripts and to zasm.

chmod +x step1.sh
chmod +x step2.sh
chmod +x do_all.sh
chmod +x zasm

## Copy files

Create a folder without spaces into "./Roms" directory and put the roms into the created folder. The total must not exceed 2032KB. Roms and MegaRoms that are not compatible will need to be converted with the corresponding [IPS patch](https://www.msx.org/wiki/How_to_use_IPS_files)  found (if it exists) in the **"./Patches/"** directory.

## Create and edit ROMs list

Run **"./step1.sh FOLDER_CREATED_NAME"**. This action will create the list of ROMs and save it in the **"./Build/EditThisList.asm"** file. Edit the list and change the filenames that are in quotes in the third column to how you want them to appear in the menu without changing the number of characters which should remain at 40 for each name.

In the second column specify the generation of MSX from which the ROM is compatible. 0 for MSX1, 1 for MSX2, 2 for MSX2+, 3 for Turbo-R. By indicating 1 (ROM MSX2), the name of the ROM will not be displayed in the list on the MSX1 computers. For a correct display, it is necessary to indicate the last ROM of each generation by adding 128 to its value. Add 64 to indicate that the ROM is using reflections of its memory.

## Create the final ROM

Run  **"./step2.sh FOLDER_CREATED_NAME"** to create the final ROM **"./Build/LoadThis.rom"**. To load it on the SCC Cartridge Flash-ROM, use [FL.COM](https://github.com/gdx-msx/FL/tree/master/FL-V133) from version 1.33.

## Create all

Run  **"./do_all.sh FOLDER_CREATED_NAME"** if you prefer create all at once.

## Note

Seems only works with 32KB or lower size ROMs.

&copy; 2025 CristianCG (SMX Team)
&copy; 2023 popolon-fr
