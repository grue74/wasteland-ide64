intro			lda #$00
				
; Clear Memory for Sprites 1 and 2
				lda #$00
-				sta $4040,x
				dex
				bpl -

				lda #$ff
				sta $7fff 						; fill last byte of the bank to hide sceen paper color
				jsr show_load_img 				; set bitmap colors and io-stuff into place

; Scroll our bitmap to the screen
; FLD example by HCL from codebase64

loop1	        bit $d011 						; Wait for new frame
		        bpl *-3
		        bit $d011
		        bmi *-3
		        lda #%00111011 					; Set y-scroll to normal position (because we do FLD later on..)
		        sta $d011
		        jmp CalcNumLines 				; Call sinus substitute routine
backcalc        lda #44 						; Wait for position where we want FLD to start
		        cmp $d012
		        bne *-3
		        ldx NumFLDLines
		        beq loop1 						; Skip if we want 0 lines FLD
loop2	        lda $d012 						; Wait for beginning of next line
		        cmp $d012
		        beq *-3
		        clc 							; Do one line of FLD
		        lda $d011
		        adc #1
		        and #7
mora		    ora #$30
		        sta $d011
		        dex 							; Decrease counter
		        bne loop2 						; Branch if counter not 0
		        jmp loop1 						; Next frame

; My own code for scrolling bitmap from the bottom as smooth as possible
CalcNumLines	lda NumFLDLines 				
		  		cmp #8 							; are we close to upper screen edge?
		  		bcs ++ 							; nope, continue scrolling with 24 lines open
		  		cmp #0 							; did we finish yet?
		  		bne + 							; nope, continue scrolling with 25 lines open
		  		jmp +++
		  +		lda #$38
		  		sta mora+1 						; mod screen lines
		  +		DEC NumFLDLines 				; screen 1 pixel up
		  		jmp backcalc
NumFLDLines	    .byte $d0

;done scrolling bitmap, time to show some sprites, open border and play music
+				lda #$00
				sta $d025
				lda #$01
				sta $d026
				lda #$0f
				sta $d028
				sta $d029
ntsc2			lda #254						; y coord for backup save 254 for pal, 246 for ntsc
				sta $d003
				sta $d005
				lda #24							; x coord
				sta $d002
				lda #48
				sta $d004
				lda #01							; sprite pointers for our text
				sta $5ff9
				lda #02
				sta $5ffa

; Print text to sprites

; First row of first sprite
				lda #34				;B
				jsr printspr 		;put B into sprite
				inc ptr2+1 			;increase sprite write address for next character
				lda #33 			;A
				jsr printspr
				inc ptr2+1
				lda #35				;C
				jsr	printspr
; 2nd sprite 1st row
				lda #$80
				sta ptr2+1
				lda #43 			;K
				jsr printspr
				inc ptr2+1
				lda #53 			;U
				jsr printspr
				inc ptr2+1
				lda #48 			;P
				jsr printspr
; 2nd row
				lda #$58
				sta ptr2+1
				lda #51 			;S
				jsr printspr
				inc ptr2+1
				lda #33				;A
				jsr printspr
				inc ptr2+1
				lda #54 			;V
				jsr printspr
; 2nd sprite 2nd row
				lda #$98
				sta ptr2+1
				lda #37 			;E
				jsr printspr
				inc ptr2+1
				lda #31				;?
				jsr printspr
				lda #8							; try to make 6581's SNAP less
				sta $d418
				jsr initsid 					; init intro sid
; Open borders so we can show our text sprites
; Borders open! Code by HCL, quick copy/paste from the codebase64
loop			lda #$f9				
				cmp $d012
				bne *-3
				lda $d011
				and #$f7
				sta $d011
				bit $d011
				bpl *-3
				ora #8
				sta $d011
; Read keyboard code by TNT / Beyond Force
				LDA #$EF
				STA $DC00
				SEC
				ROR A
				BIT $DC01
				BPL continue
				STA $DC00
				LDA #$02
				AND $DC01
				BEQ backupsave
				lda #$00
				sta $DC00
				lda #$ff
				cmp $DC01
				bne continue
				jsr playsid
				JMP loop

; make backup copy of the savegame file
backupsave		lda #8									; soften 6581 snap by lowering volume before mute
				sta $d418
				ldx #$17								; empty sid registers, we need to mute intro music
				lda #$00
 -				sta $d400,x
				dex
				bpl -
				lda #$36								; kernal on for the initial fileops
				sta $01
				jsr savebackup 							; save backup copy of the save
				lda #$35 								; kernal off as we dont need it anymore
				sta $01
				jmp +
; load the game and patch it to work with our loader and other enchancements
continue		; Init SID with empty values
		        lda #8									; soften 6581 snap by lowering volume before mute
				sta $d418
		        ldx #$17
				lda #$00
 -				sta $d400,x
				dex
				bpl -
+				lda #$00								; sprites off					
				sta $d015
				lda #0 									; silence of the sids
				sta $d418

				rts

show_load_img	
; copy loader bitmap colors into place
				lda $5001							; get screen paper colour
				sta $d021							; and set it
				ldx #$00
 -				lda $5002,x
				sta $5c00,x
				lda $53ea,x
				sta $d800,x
				lda $5102,x
				sta $5d00,x
				lda $54ea,x
				sta $d900,x
				lda $5202,x
				sta $5e00,x
				lda $55ea,x
				sta $da00,x
				lda $5302,x
				sta $5f00,x
				lda $56ea,x
				sta $db00,x
				inx
				bne -

				lda $dd00 							; set VIC-II bank to $4000-$7fff
				and #$fc
				ora #2
				sta $dd00
				lda #$3f 								
				sta $dd02
				lda #%00011000 						; enable multicolor mode with 40 cols
				sta $d016							
				lda #%01111000						; sceeen $5c00, bitmap $6000 
				sta $d018
				lda #%00101011						; irq on top of the screen and bitmap mode on
				sta $d011 
				lda #$ff
				sta $d019							; just in case. ack all pending irqs
				lda #$b0
				sta $d012 							; set the raster line we want irq to happen
				rts

; Plot Text into sprite data, bit clumsy but it works
printspr		ldx #$C6 							; seek letter and poke it to spritedata at $4040 and $4080
				stx ptr2-1
				ldy #0
				asl 
				asl
				asl 								; multiply by 8, asl = 2x, 3xasl = 8x
				bcc + 								; did we overflow? if not continue at +
				inc ptr2-1 							; we did overlow, move to next block
+				tax 								; move our multiplied character into x index
-				lda $c600,x 						; load character data
ptr2			sta $4040,y 						; put it in spite
				inx 								; move to next character byte
				iny	
				iny
				iny
				cpy #24								; Sprite data is strange so we need to copy 8 bytes and skip 3 values each round.
				bne -
				rts
