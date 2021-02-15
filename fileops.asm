fopen			
; Open file 13 called "SAVE" for saving game roster into separate file for transferring it to new game.
				lda #13									; file number
				ldx $ba									; current drive
				tay
				jsr setlfs								; setup file for opening
				lda #6 									; lenght of the filename
				ldx #<savename							; location of the filename to open
				ldy #>savename
				jsr setnam								; setup filename and name lenght
				jsr open								; Open file

; Open mainfile "WL"
				lda #12									; file number
				ldx $ba									; current drive
				tay
				jsr setlfs								; setup file for opening
				lda #4 									; lenght of the filename
				ldx #<filename							; location of the filename to open
				ldy #>filename
				jsr setnam								; setup filename and name lenght
				jsr open								; Open file

; Open command channel for seeking main file
				lda #15									; Setup Command channel to seek_pos
				ldx $ba									; Current drive
				tay										; Secondary address
				jsr setlfs
				lda #$00
				jsr setnam
				jsr open								; open cmd channel

; save current filetables, zeropage locations and vector jump locations for our loader. This is for adding compability
				ldx #$1e-1								; swap vectorspace
-				lda $0259,x
				sta filetables,x
				dex
				bpl -
				ldx #$54-1 								; -1 since we use dex bpl method and zero counts as well
-				lda $70,x
				sta zp_swap,x
				dex
				bpl -
				jsr vectorcopy
				lda #$00 								; set initial disk side before trying to load
				sta floppy_side
				rts

; open file 11 for saving mansave file
savebackup		lda #5									; Green border for indicating we're in saving biz
				sta $d020
				lda #11									; file number
				ldx $ba									; current drive
				tay
				jsr setlfs								; setup file for opening
				lda #12									; lenght of the filename
				ldx #<mansavename						; location of the filename to open
				ldy #>mansavename
				jsr setnam								; setup filename and name lenght
				jsr open

; Load roster into memory for saving it to mansave 
				lda #$00								; set load'n'save address
				sta $fb
				lda #$90
				sta $fc
				ldx #13									; file number
chkin2_			jsr $ffff								; set for input
				lda #$fb 								; c64 address to load to
				ldx #0						 	
				ldy #8									; set to load 8 blocks
				jsr read
clrchn2_		jsr $ffff

; save savebackup
				ldx #11									; file number
chkout2_		jsr $ffff								; set for input
				lda #$fb 								; c64 address save from
				ldx #0						 
				ldy #8									; set to save 8 blocks
				jsr write
clrchn3_		jsr $ffff
				lda #11									; close savebackup
				jsr close
				lda #0									; Enough of this green thing, back to black
				sta $d020
				rts

vectorcopy		ldx #1									; Copy kernal jump locations from the vectors
-				lda $31e,x								; So we dont need to care if they get 
				sta chkin_+1,x							; overwritten by the game load (they do...)
				sta chkin2_+1,x
				lda $320,x								
				sta chkout_+1,x
				sta chkout2_+1,x
				lda $322,x
				sta clrchn_+1,x
				sta clrchn2_+1,x
				sta clrchn3_+1,x
				lda $326,x
				sta chrout_+1,x
				dex
				bpl -
				rts

mansavename	  	.text "SAVEBACKUP,W"
filename 		.text "WL,M"
savename		.text "SAVE,M"