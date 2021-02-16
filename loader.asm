; Loaderblob, uses memory from $fc00-$ffff

loader_code:	
				.logical $fc00
				jmp Loader_Call
save_table:   	.byte   0,  0,  0,  0,  0,  0,  0,  0; 0
                .byte   0,  0,  0,  0,  0,  0,  0,$ff; 8
                .byte $ff,  0,$ff,$ff,  0,  0,  0,  0; $10
                .byte   0,  0,  0,  0,  0,  0,  0,  0; $18
                .byte   0,  0,$ff,  0,  0,  0,  0,  0; $20
                .byte   0,  0,  0,  0,  0,  0,  0,  0; $28
                .byte   0,  0,  0,  0,  0,  0,  0,  0; $30
                .byte   0,  0,  0,  0,  0,  0,  0,  0; $38
                .byte   0,  0,  0,  0,  0,  0,  0,  0; $40
                .byte   0,  0,  0,  0,  0,  0,  0,  0; $48
                .byte   0,  0,  0,  0,  0,  0,  0,  0; $50
                .byte   0,  0,  0,  0,  0,  0,  0,  0; $58
                .byte   0,  0,  0,  0,  0,  0,  0,  0; $60
                .byte   0,  0,  0,  0,  0,  0,  0,  0; $68
                .byte   0,  0,  0,  0,  0,  0,  0,  0; $70
                .byte   0,  0,  0,  0,  0,  0,  0,  0; $78
                .byte   0,  0,  0,  0,  0,  0,  0,  0; $80
                .byte   0,  0,  0,  0, $f	  		 ; $88

fileaddr_tbl:	.byte   0,  0,$15,  0,$2a,  0,$3f,  0	;0
				.byte $54,  0,$69,  0,$7e,  0,$93,  0	;8
				.byte $a8,  0,$bd,  0,$d2,  0,$e7,  0	;16
				.byte $fc,  0,$11,  1,$26,  1,$3b,  1	;24
				.byte $50,  1,$65,  1,$78,  1,$8b,  1	;32
				.byte $9e,  1,$b1,  1,$c4,  1,$d7,  1	;40
				.byte $ea,  1,$fc,  1, $e,  2,$20,  2	;48
				.byte $32,  2,$44,  2,$56,  2,$67,  2	;56
				.byte $78,  2,$89,  2,$9a,  2 			;64 + 5 (+1 is from next table) we get 70 values, 2 bytes/track as we get 35 tracks

fileaddr_tbl2:	.byte   0,  0,$ab,  2,$56,  5,  1,  8 	;24. bit index for wl-file, 8 values, 2 for each disk side.
filesave_tbl:	.byte   0,$23,$46,$69,$20

											; this is seekcmd for big wl file
seekcmd			.byte $50,12				; P cmd + secondary address
seekloc			.byte 0,0,0,0,13			; cmd continues with seek address, bits 0-7, 8-15, 15-23 and 24-31 in this order

seekcmd2		.byte $50,13,0,0,0,0,13		; P cmd + secondary address + location, this is for save file

spdzone			.byte 36,31,25,18
step			.byte  6, 7, 8,10
maxsec			.byte 17,18,19,21
game_time_patch .byte $a9,$01,$8d,<timetest,>timetest,$24,$00,$4e,$8d,$7e,$90,$0E
seed			.word $bfed
                .here

; This code block needs to be here at $fd0b if you move these game wont work!
                *=loader_code+$10b
                .logical $fd0b
Step_and_return_sector:
				dey                     		; current sector on y
				bpl ++				     		; if sector positive exit
				dex                     		; decrement track number
				cpx #$12
				bne +			 			    ; if track 18, skip
				dex                     		; if track was 18, proceed to track 17
+				lda $c930,x 	        		; read max sectors on track
				tay                     		; return sector on y
+				rts

				ldx $11 						; these locations are referenced in game code at "wl" bin.
				ldy $10
				lda #0
				pha
				lda #0
				sta $fe
				lda #$5a
				sta $ff
				pla
				jmp $03aa 						; load_data
; Code block ends here

filetables		.fill $1e,$bf 					; space for vital loading tables and game code swap
zp_swap:		.fill $54,$bf 					; space for zp-registers and game code swap    			

restore_save_tbl:	
				lda #$65						; Load block from predefined $00056500 address from wl,reu to $fc03
				sta seekloc+1
				lda #$5
				sta seekloc+2
				lda #$8c 						; Modify load code to get $8c bytes instead of default 1 block
				sta savehack+1 
				lda #$00						; load 0 blocks
				sta savehack+3
				lda $fe 					
				pha		 						; Store original save ram location to stack
				lda $ff
				pha
				lda #$fc 						; set load address $fc03
				sta $ff
				lda #$03
				sta $fe
				jsr read_from_file				; commence loading
				ldx #$01 						; Restore original 1 block load lenght
				stx savehack+3
				dex
				stx savehack+1
				pla  		 					; Restore original save ram location
				sta $ff
				pla 
				sta $fe
				rts				

loader_adr				
read_from_file:	jsr swap_memory2 				; swap zp-locations
				jsr special_selfoverwrite 		; check if we are loading on $0200 or $f400 and handle it
				jsr seek_pos					; find position to read from
				ldx #12							; file number
chkin_			jsr $ffff						; set for input
				lda #$fe 						; c64 address to load to
savehack:		ldx #0						 
				ldy #1							; set to load 1 block
				jsr read
				jsr special_selfoverwrite
				jsr restorel
end:			jsr clrchn_
swap_memory2:	jsr swap_memory
				ldx #$54-1
-				ldy zp_swap,x
				lda $70,x
				sta zp_swap,x
				sty $70,x
				dex
				bpl -
				rts

special_selfoverwrite:
				lda $ff 						; check if we are loading on ourselves
				cmp #2  						; at $0200 page
				bne + 							; if not, skip
				geq swap_memory					; if we are then restore healthy values
 +				cmp #$f4 						; are we trying to load game save?
				beq + 							; if we are, handling "ro" file 13, do special tricks
 -				rts								; if not, we dont have anything to do here and return
 +				lda floppy_side   				; are we on floppy_side = 0, if not then exit and proceed normally
				bne -
 				lda #$08 						; we want to load whole save at one go, 8 blocks
				sta savehack+3 					; modify to load 8 blocks instead of 1
				inc chkin_-1 					; file 13 which is RO
				lda #<seekcmd2					; modify seek to start of roster file
				sta chrout_-2 					; mod continues
				rts

restorel:		lda #12 						; restore wl datafile number (12)
				sta chkin_-1
				lda #$01 						; restore blocklenght for loading
				sta savehack+3
				lda #<seekcmd 					; restore original seek for loading wl file
				sta chrout_-2
				rts

swap_memory:	ldx #30-1						; swap filetables
 -				ldy	filetables,x
				lda $0259,x
				sta	filetables,x
				tya
				sta	$0259,x
				dex
				bpl -
				rts

chkout_			jmp $ffff
seek_pos:		ldx #15 						; open CMD channel for output
				jsr chkout_ 
				ldx #0  						
 -				lda seekcmd,x       			; send it to cmd channel #15
chrout_			jsr $ffff 						; using chrout
				inx
				cpx #8							; lenght of the seek cmd string
				bne -
clrchn_			jmp $ffff 						; call clrchn

write_to_file: 	jsr swap_memory2				; swap memory
				jsr check 						; check if we're saving SAVE file
				jsr seek_pos 					; seek file position for save
filno			ldx #12							; file number
				jsr chkout_						; set for input
		
				lda #$fe 						; c64 address save from
				ldx #0						 
blo				ldy #1							; set to save 1 block
				jsr write
				jsr clrchn_
				jsr seek_pos					; flush written data to disk
				jsr restore 					; restore default save
				jmp end

check:			lda $ff
				cmp #$f4 						; check if we are trying to save roster
				bcc +	 						; nope we are not: exit					
				lda floppy_side 				; are we saving to floppy_side = 0, if not exit
				bne +
savefile:		inc filno+1						; if we are at block $f400, save to savefile $f400-$fbff
				lda #<seekcmd2
				sta chrout_-2
				lda #$08 						; save 8 blocks at the time
				sta blo+1
 +				rts

restore:		lda #12 						; restore wl datafile number (12)
				sta filno+1
				lda #$01 						; restore blocklenght for saving
				sta blo+1
				lda #<seekcmd 					; restore seek cmd for WL file
				sta chrout_-2
				rts

Loader_Call:    sta ldr_cmd 					; store registers containing needed info
                stx sector
                sty track
 			    lda 1 							; store original value of $01 so we can restore it later
                pha
                lda #$35 						; Switch kernal and basic rom off (kernal already was, since we are here)
                sta 1
                sta $d027 						; set indicator sprite green
sprite          lda #$f6 						; change spritepointer for bigger disk access indicator
                sta $5ff8
                inc $d015 						; turn sprite0 on
                lda ldr_cmd
                cmp #2 							; check if we got called for save
                beq Save
                bcs Exit_Loader 				; if command is something else than 0, 1 or 2, gtfo
					
Load:			lda floppy_side 				; check if we are on floppy 0, its a special case. If we are trying to save
				bne + 							; savegame on floppy 0, we want it on file instead of wl image.
				lda $ff							; check if we trying to load/save from $f500 ->
				cmp #$f5 						; if so, then exit as we already handled whole 8 blocks already
				bcs Exit_Loader					; at $f400
 +				jsr Find_Load_Addr				; find next track/sector to load from and calculate pos in "wl" file
				jsr read_from_file				; call Loader
				ldx ldr_cmd
				dex
				bne Exit_Loader					; if 0 gtfo
				lda $ff
				cmp $fd 						; check if we got to top of the HI address to load
				beq Exit_Loader					; if all blocks done, exit
				inc $ff 						; move to next block
				ldx track 								
				ldy sector
				jsr Step_and_return_sector		; find next track/sector
				stx track 						; store new track / sector values for the loader
				sty sector
				jmp Load 						; check if theres more

Save: 			sta $d027						; turn disk indicator sprite red
				jsr restore_save_tbl            ; Load $8c bytes to filesave_tbl
				clc 							; clear carry as we do math
				ldx floppy_side					; value 1-4
				lda filesave_tbl,x 				; $23,$46,$69,$20
				adc track 						; + track (max value $8c)
				tax
				lda #$ff
				sta save_table-1,x				; mark $ff on savetable, theres no track 0 so -1 from table index
				lda floppy_side					; are we on floppy_side 0, if not, continue on
				bne +
				lda $ff
				cmp #$f5 						; we saved whole thing at #f4, so exit
				bcs Exit_Loader
 +				jsr Find_Load_Addr 				; find Sector to save to
				jsr write_to_file 				; Finally do write

Exit_Loader:   	lda #$00
				sta $fc
				sta $d015 						; sprites off
				sta timetest 					; stop running time
				pla 							; return state of the memory configuration
				sta 1
				clc 							; sec would cause i/o error
				rts

; this routine which calculates position in wl image is made by mood_swing
Find_Load_Addr: 								
				ldy track						; get current track 
				dey								; since theres no track 0 and but our index starts from 0, decrement one  
				tya								; now we have 0-starting track on A
				asl 							; shift one bit left, 0=0, 1=2, 2=4, 3=6
				tay 							; make shifted track our y-index to the table
				lda floppy_side 				; get floppyu side we're currently on (0-3)
				asl 							; shift left
				tax 							; make it our x-index
				lda fileaddr_tbl2,x 			; read 24th bit location of current floppy we're on (0-3)
				adc fileaddr_tbl,y 				; add track index 0-34 (theres 70 values in total, 2 for each track 16-bits you know)
				sta seekloc+1 					; store result as bits 8-16 in our seek value
				lda fileaddr_tbl2+1,x 			; read bits 8-16 for disk location in wl file
				adc fileaddr_tbl+1,y 			; add bits 0-7
				pha 							; store upperbyte into stack

				; This code is made by TNT / Beyond Force, he solved my out of memory space problems here.
				; Original routine took way too much space
				; Routine calculates sector position on a track considering disk interleave

				lda track						; we calculate interleave here to find next block
				ldx #4 							; we have four speedzones
 -				dex								; pre-decrement to hit all the values on the table
				cmp spdzone,x 					; does current track belong to this speedzone?
				bcs -	 						; nope, try lower one
				lda	#0							; start from physical sector 0
				ldy	sector						; logical sector is number of interleave steps to take
				beq	++							; if zero, we are done
 -				clc								; take one interleave step forward
				adc	step,x				
				cmp	maxsec,x					; check if we exceeded track size
				bcc	+ 							; nope skip
				sbc	maxsec,x					; if so, we go back to the allowed range
 +				dey
				bne	-							; and repeat as long as there are steps to be taken
				; end of interleave calc code by TNT
				
 +				clc 							; clear c
				adc seekloc+1					; add previously calculated value of bits 8-16
				sta seekloc+1 					; poke interleave calculated address into seek location address
				pla 							; get upper byte
				adc #0 							; and adc #1 if carry is set from previous adc seekloc+1
				sta seekloc+2; 					; poke byte 17-24 bytes of our seek loc
				rts
; end of original code by mood_swing

; Turbo compatible delay code, original game uses busy loop, doesn't behave with faster cpu
delay			beq + 						; A=0 means no delay, exit. This routine is bit tricky as we cannot trash x or y
				sec							; since we do math, set c accordingly
 -				pha							; store A
				lda #$1 					; wait 2 rasterlines
 - 				bit $d012
				beq -
 -				bit $d012
				bne -
				pla 						; get A
				sbc #$01 					; substract one from A	
				bne ---						; are we at A=0 yet? if not then repeat!
 +				rts

; Keyboard reading and time running code, runs in IRQ.
checkkbd		lda $7e8C					; check if we at the game code, intro breaks up if we trigger there
				cmp #$24
				bne ext	 					; if not, exit.
				ldx timetest
				lda #$fd 					; we want to read left shit (shiftlock)
				sta $dc00
				lda #$80 					; its much more convenient to wait healing
				and $dc01 					; this way
				beq trigger					; if l-shift was pressed, proceed to speed up time
				lda #3
				sta $d031					; 4 Mhz speed 
				txa			 				; size optimize things if 0 then exit, if 01 then x=1 which trigs later
				beq +
				clc							; run clocks, ~30s / tick which is roughly the same
				lda $b4						; as in original game
ntsc			adc #$2c 					; $2c for pal, $24 for ntsc
				sta $b4
				lda #$00
				adc $b5
				bcc +	 					; if time didnt overflow, save $b5 and exit
 trigger		stx $7e8D					; trigger time
				ldx #$0f
				stx $d031					; 48Mhz mode on for added speed; we want warp speed shift pressed
 +				sta $b5 					; reset also hi-byte of our time counter
 ext			jmp $2967


; Check if game wait code got overwritten and replace it our turbo friendly version if it does
; Random routine is good place to check as if it gets run very often.

random			lda $7e87 					; game does load on itself on some occasion
				cmp #$a9					; check if we need to patch passage of time
				beq + 						; nope, we are running on our own code, skip restore
				cmp #$7e					; are at intro code?
				beq +						; yes we are, exit
				txa
				pha							; store x as we are going to trash it
				ldx #12-1
 -				lda game_time_patch,x		; restore our own code
				sta $7e87,x
				dex
				bpl -
				pla 						; restore x
				tax

; Generate better random numbers. This code is from Codebase64!
 +				lda seed+1
        		lsr
        		lda seed
        		ror
        		eor seed+1
        		sta seed+1					; high part of x ^= x << 7 done
        		ror							; a has now x >> 9 and high bit comes from low byte
        		eor seed
        		sta seed					; x ^= x >> 9 and the low part of x ^= x << 7 done
        		eor seed+1
        		sta seed+1					; x ^= x << 8 done
        		rts
; End of code!       		
				.cerror * > $fffa, "Program too long!"
				.here