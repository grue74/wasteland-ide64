; 
; Wasteland IDE fix by Grue & TNT
; 
; 	This fix is based on the Wasteland 1MB REU version, which was posted in Lemon64 forums in 2013 by user mood_swing.
;	He has since sadly removed all postings and links to his fix.
;	In the end, I had to write much more code and figure out strange behavior due to my inexperience on how
;	loading works on C64. Problematic is also that the game uses almost all the available memory
;	
;	I hope this source code will help to fix more games for IDE64, 
;	
; 
; 	Enchancements done so far: 
;
; 		Memory optimizations in the loader, whopping 4 bytes free currently at $fc00-fff9 area
;		Save game in separate "SAVE" file
;		Time handler moved from busyloop to IRQ, now time wont run too fast with Turbo
;		Its now possible to hold left shift or use shiftlock for speeding up the time for healing,
;		 but be sure to be in safe place to avoid random encounters.
; 		Reimplemented random routine game uses, it was quite bad for accelerated 6510 usage, original
;		 routine uses $d012 and $dc04 for entropy, when running cpu with 48Mhz speed those wont help much..
;		 New routine is from codebase64.org.
;		Its now possible to use original game image, just create play .d64's from the original game and merge
;		 and save as "WL"
;		Implemented Load/Save indicator as green/red sprite at the lower right corner of the screen.
;		It is now possible to make backup copy of the "SAVE" file during boot. Green border marks successful backup
;		Detection of faster cpu and adjusting game speed accordingly.
;		Ultimate 64 users get extra speed if they have enabled Turbo Control: U64 Turbo Registers
;			
;		Original cover art loading picture by Duce / Extend
;
;		TODO:
;		 - Implement transferring roster from the old save file to start a new game.
;			 
; 			 
;
;	Thanks to:
; 	Soci / Singular for help and code!
;	TNT / Beyond Force for code, help, support and teaching me 6502 asm.
;	Trurl / Extend for help, test and suggestions
;   Zer0-x / Kasettilamerit for a such great tool U64 debug stream!
;	Codebase64 for being such great reference!
;
;	All IDE64 fans!
; 
;	Tools used for making this IDE64 fix possible, not in any special order
;
;	IDE64
;	64tass
;	010 Editor
; 	Ida pro
;	Ultimate 64 + ucodenet
;	U64 debug stream
;	C64debugger
;	Vice
;	Sublime text 3
;	Max roast level Coffee

;	.cpu "6502"


track			= $f8
sector			= $f9
ldr_cmd			= $f3
load_until		= $fd
load_adr_lo		= $fe
load_adr_hi		= $ff
open			= $ffc0
close			= $ffc3
setnam			= $ffbd
setlfs			= $ffba
read			= $def4
write			= $def1
NMI				= $04f6
IRQ				= $04f9
floppy_side		= $fffc
timetest		= $fffd


				* = $3000
start			lda #$00 								; black is very beautiful, dont you agree?
				sta $d020
				sta $d021

; PAL / NTSC check, Grahams variant from codebase64
w0				LDA $D012
w1				CMP $D012
    			BEQ w1
    			BMI w0
; end of codebase64 code

	   			cmp #$37								; check are we running PAL system
    			beq pal									; if so, then skip ntsc fixes
  				lda #$24 								; as ntsc clock runs 60hz, we need to adjust our time running code vs pal 50hz
  				sta ntsc-$c000+1
  				lda #246								; we need to raise up save backup sprites as they are not visible on ntsc screen.
  				sta ntsc2+1

; check speed of the cpu
pal				lda #3
				sta $d031								; set U64 turbo to 4Mhz
				ldx #$00								; clear our counter				
-				lda $d012								; wait for rasterline $ff
				cmp #$ff
				bne -
-				inx										; increase counter
				cpx #$00
				beq +									; if counter did overflow, proceed to save max value.
				lda $d012
				cmp #$8									; wait ~8lines (I know we start from 0)
				bne -
				stx $c000 								; after waiting for 8 lines, save counter value
				jmp ++
+				ldx #$ff								; With serious cpu speed, counter did overflow and we save max value
				stx $c000								; save counter value
				
+				lda #0 									; set default action not to backup save file
				sta $c001

; Start initial game setup
				sei										; Disable interrupts as we switch kernal rom off
				lda #%00101011							; irq on top of the screen and bitmap mode on, screen off
				sta $d011 
				lda #$35
				sta $01
				lda #$7f
				sta $dc0d 								; set IRQ interrupts
				sta $dd0d								; set NMI interrupts
				lda $dc0d 								; clear them by reading
				lda $dd0d
				lda #$2f								; setup cpu data direction registers to defaults
				sta $00
				ldx #$ff
				txs 									; set stackpointer to default value

				ldx #4 									; transfer loader code into its place $fc00-$ffff
				ldy #0 									; this will also set NMI & IRQ addresses
mod:			lda loader_code,y
				sta $fc00,y
				iny
				bne mod
				inc mod+2
				inc mod+5
				dex
				bne mod

-				lda game_dat_tbl,y						; copy block of game data into its place
				sta $5b00,y
				iny
				bne -

				lda #$34
				sta $01 								; switch IO addresses off for RAM under IO
-				lda io_code_tbl,y 						; Copy code under IO space
				sta $dd80,y
				iny
				bpl -
				
				lda #$36
				sta $01	 								; IO back on, Basic off, Kernal on
				jsr fopen								; open files
				lda #$35								; Kernal off
				sta $01

; load game font into memory for enabling text showing sprites
				lda #$00
				sta load_adr_lo
				lda #$c6
				sta load_adr_hi 
				clc
				adc #3 									; Load 3 blocks
				sta load_until 							
				lda #1 									; 1=Load
				ldy #$22								; Track 34
				ldx #$e 								; Sector 14
				jsr Loader_Call							; Load $c600-$c9ff

; Set disk access indicator sprite
				lda #1
				sta $d010 								; sprite 1 msb 1
				sta $d01d								; sprite 0 x-expand
				sta $d017								; sprite 0 y-expand
				sta $d027								; sprite 0 color
				lda #$fe					
				sta $d01c								; sprite 0 hires other MC
				lda #84									; 84
				sta $d000								; sprite 0 coord x
				lda #245								; 252
				sta $d001								; sprite 0 coord y
				lda #%00000110
				sta $d015								; sprites on
				lda #$00								; sprite pointer for sprite 0
				sta sprite+1
				lda #$ff 								; make a sprite
				ldx #$3f
 -				sta $4000,x
				dex
				bpl -

				jsr intro								; show intro

; now we are finally in real game loading bizniz, load main game code $0200 - $2fff
; loading on $0200 is really tricky as load/save vectors, filetables etc are there which
; ide64 or any other kernal load compatible loading needs. There special code to handle this
; but it consumes memory which we dont have plenty as the game uses whole 64k

				lda #0
				sta load_adr_lo
				lda #2
				sta load_adr_hi
				clc
				adc #$2e 								; load $2e blocks
				sta load_until
				lda #1
				ldy #$22 								; Start transfer from Track 34
				ldx #$a 								; Sector 10 and continue there with interleave tables
				jsr Loader_Call							; Load $0200-$2fff

; load game intro parts into memory
				lda #0
				sta $d020								; change back to black
				sta load_adr_lo
				lda #$7e
				sta load_adr_hi
				clc
				adc #$f 								; get 15 blocks
				sta load_until
				lda #1
				ldy #4 									; Start Track 4
				ldx #$10 								; Sector 16
				jsr Loader_Call							; Load $7e00-$8dff

; Done loading and all pieces are on place, now do some patching to use our own loader and enchancements

; Adjust game delay routine depending on our little cpu speed test earlier			

				lda $c000 								; speedcheck result is here
				cmp #$50								; did we run faster than 1Mhz?
				bcc +								 	; naah
				ldx #$08 								; ok, we have some turbo action here, adjust some timings	
				ldy #$02
				jmp ++
+				ldx #$0b								; suitable values for 1Mhz machine
				ldy #$4
+				stx $2106								; original $0b : character Animation speed!
				sty $2530 								; original $04 : game turn delay, also in intro.

; Intro stuff delays, calls to standard routine with A
				lda #$10 								; original $19 ; in sound routine - siren speed
				sta $7ef6

; Patch Game to jump to our own delay routine
				lda #$4c
				sta $242b
				lda #<delay
				sta $242c
				lda #>delay
				sta $242d

; Patch IRQ routine jsr to check shift lock key
				lda #<checkkbd
				sta $2959
				lda #>checkkbd
				sta $295a

; Patch random number routine code to jump to our own code with little mod
				lda #$20
				sta $24e6
				lda #<random
				sta $24e7
				lda #>random
				sta $24e8
				lda #$6d								
				sta $24e9
				lda #$12
				sta $24ea
				lda #$d0
				sta $24eb

; patch disk side number -1 routine
				ldx #$00
-				lda disk_side_patch,x
				sta $18c4,x
				inx
				cpx #9
				bne -

; Patch Disk Side Requesters, as we dont need them anymore
				lda #$ea
				ldx #$00
-				sta $8228,x
				sta $8284,x
				inx
				cpx #5
				bne -

; Patch Intro menu text, remove "Utils". It also removes possibility to enter Utils meny all together, handy!
				ldx #$05
				lda #$20
-				sta $81b3,x
				dex
				bpl -

; Patch Screen shake bug which was in original game, it restored upperbit also in $d011 value which we dont want.
				lda #$8b 								; value for x
				sta $0754
				lda #$30								; bmi
				sta $076a
				lda #$8f 								; sax
				sta $0771

; Set Screen for originakl game intro gfx
				ldx #$00
				stx $d020
				stx $d021								; set Screen + Color ram for bitmap gfx
 -				lda #$01
				sta $d800,x								; set color ram
				sta $d900,x
				sta $da00,x
				sta $db00,x
				lda #$6f
				sta $5c00,x								; screen ram location game uses
				sta $5d00,x
				sta $5e00,x
				sta $5f00,x
				inx
				bne -
				
; Set load indicator sprite pointer and position				
				lda #$f6
				sta sprite+1							; restore more suitable sprite pointer
				lda #242					
				sta $d001								; sprite 0 coord y

; Set NMI and IRQ, Then we are ready to rock'n'roll
				lda #<NMI
				sta $fffa
				lda #>NMI
				sta $fffb
				lda #<IRQ	
				sta $fffe
				lda #>IRQ
				sta $ffff

; Finally, enable irq and jump to intro!

				lda #$01								; enable IRQ
				sta $d01a
				jmp $7e00								; Start Intro

disk_side_patch .byte $a6,$6b,$ca,$8e,<floppy_side,>floppy_side,$4c,$9e,$18

				.include "intro.asm"
				.include "initbin.asm"
				*=$3c00
				.include "loader.asm"
				.include "fileops.asm"
				*=$5000
				.binary "waste_color.bin"
				*=$6000
				.binary "waste_data.bin"
				
				sidfile = "Ambient_Music.sid"        ; file name
				header  = binary(sidfile, $00, $7e)
				initsid = header[$b:$9:-1]   ; init address (big endian)
				playsid = header[$d:$b:-1]   ; play address (big endian)
				*       = header[$7c:$7e]    ; use loading address (little endian)
        		.binary sidfile, $7e ; load music data