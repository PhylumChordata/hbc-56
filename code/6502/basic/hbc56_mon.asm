; BASIC for the HBC-56

!src "hbc56kernel.inc"

!src "basic.asm"

SAVE_X = $E0		; For saving registers
SAVE_Y = $E1
SAVE_A = $E2

; put the IRQ and NMI code in RAM so that it can be changed

IRQ_vec	= VEC_SV+2	; IRQ code vector
NMI_vec	= IRQ_vec+$0A	; NMI code vector

; reset vector points here

hbc56Meta:
        +setHbcMetaTitle "HBC-56 BASIC"
        rts

RES_vec
hbc56Main:
        sei
        jsr kbInit
        jsr tmsModeText
        +tmsSetAddrNameTable
        lda #' '
        ldx #(40 * 25 / 8)
        jsr _tmsSendX8          ; clear the screen

        ; set up the display
        +tmsSetColorFgBg TMS_WHITE,TMS_DK_BLUE
        +tmsEnableOutput
        +tmsEnableInterrupts    ; Gives us the console cursor, etc.

        lda #HBC56_CONSOLE_FLAG_CURSOR
        sta HBC56_CONSOLE_FLAGS

	LDY	#END_CODE-LAB_vec	; set index/count
LAB_stlp
	LDA	LAB_vec-1,Y		; get byte from interrupt code
	STA	VEC_IN-1,Y		; save to RAM
	DEY				; decrement index/count
	BNE	LAB_stlp		; loop if more to do

        cli

	JMP	LAB_COLD		; do EhBASIC warm start

ASCII_RETURN    = $0A
ASCII_BACKSPACE = $08

; byte out to screen (TMS9918)
SCRNout
        sei     ; disable interrupts during output
        stx SAVE_X
        sty SAVE_Y
        sta SAVE_A
        cmp #ASCII_RETURN
        beq .newline
        cmp #ASCII_BACKSPACE
        beq .backspace

        ; regular character
        jsr tmsSetPosConsole
        lda SAVE_A
        +tmsPut
        jsr tmsIncPosConsole


.endOut:
        ldx SAVE_X
        ldy SAVE_Y
        lda SAVE_A
        cli
        rts


.newline
        +tmsConsoleOut ' '
        lda #39
        sta TMS9918_CONSOLE_X
        jsr tmsIncPosConsole
        jmp .endOut

.backspace
        +tmsConsoleOut ' '      ; clear cursor
        jsr tmsDecPosConsole
        jsr tmsDecPosConsole
        +tmsConsoleOut ' '
        jsr tmsDecPosConsole
        jmp .endOut

	RTS

; byte in from keyboard

KBDin
        jmp kbReadAscii ; return character in 'A', set carry if set

OSIload				        ; load vector for EhBASIC
	RTS

OSIsave				        ; save vector for EhBASIC
	RTS

; vector tables

LAB_vec
	!word	KBDin                   ; byte in from keyboard
	!word	SCRNout		        ; byte out to screen
	!word	OSIload		        ; load vector for EhBASIC
	!word	OSIsave		        ; save vector for EhBASIC

END_CODE
