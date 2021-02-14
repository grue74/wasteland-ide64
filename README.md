# Wasteland-IDE64
Commodore 64 Wasteland game modification for IDE64

Wasteland IDE fix by Grue and lots of help from TNT / Beyond Force

This fix was initially based on the Wasteland 1MB REU version posted in Lemon64 forums in 2013 by user mood_swing. He has since sadly removed all postings and links to his fix. While the mood_swings REU version was an excellent starting point, loading from real devices works so much differently that's there's not much code left from the original REU version. Problematic is also that the game uses almost all the available memory available on Commodore 64.

Please note that this game will write its progress directly into the WL file, so you need to keep a copy of the original and have a separate file for playing. The only way to restart the game totally from scratch is to use a new game image file. I modded the game to save into a separate SAVE" file to start a new game with the old roster like the original game intended. I haven't coded the tool yet. Maybe I never will. Time will tell.

Please make sure to make copies of your SAVE file, it is easy to get stuck, rendering your savegame unusable.

I added an indicator on the upper right corner of the screen to show when the game is loading or saving. When there's L, it's loading and S when saving. There is a Utils menu presented on the intro screen, it is not working as its meaning is just to make new game floppies, and since we are not using floppies, you do not need it. So it's completely normal that the game will hang if you try to load it. 

Enhancements done so far: 

- Save the game in a separate "SAVE" file.
- Time handler moved from busy loop to IRQ-based counter. Now, it won't run too fast with Turbo.
- PAL / NTSC adjustments to the Time counter.
- It is now possible to hold left shift or use shift lock for speeding up the time for healing, but be sure to be in a safe place to avoid random encounters.
- Much better random number generator was added. The original routine was using $d012 and $dc04 for entropy. When running CPU faster speed, those get more and more non-random in nature. The new code is from codebase64.org.
- It is now possible to use original game floppies to create play image "WL" Just merge existing d64's if your play floppies and rename it to WL, and commence playing. You need a clean "SAVE" file and choose not to load your latest save on the Intro screen to get going.
- Implemented Load/Save indicator as green/red sprite at the lower right corner of the screen. Green means load and Red Save.
- It is now possible to make a backup copy of the "SAVE" file during boot.
- Detection of faster CPU and adjusting game loop delays accordingly.
- Ultimate 64 users get extra speed if they have enabled Turbo Control: U64 Turbo Registers in U64 settings. Other CPU speeder users will also benefit, but the U64 users game will automatically adjust between 4Mhz and 48Mhz speed depending on the situation.
			
TODO:
 - Implement transferring roster from the old save file to start a new game.
 

Thanks to:
- Soci / Singular for help and code!
- TNT / Beyond Force for code, help, support, and teaching me finesse of 6502 asm.
- Codebase 64, beneficial resource for common problems and solutions.
- Trurl / Extend for help, testing, suggestions, and ongoing testing to find those little bugs and annoyances. You can thank Trurl for such a smooth experience.
- All my friends on the IRC channel bearing my ongoing frustration with the creepy irradiated wasteland bugs.
	
And to all IDE64 fans!

Tools used for making this IDE64 fix possible, not in any particular
order:

- IDE64
- Ultimate 64 + ucodenet
- Sublime Text 3
- 64tass
- 010 Editor
- Ida pro
- C64debugger
- Ghidra
- Vice
- Max roast level Coffee

// Grue 2021
