; 6502 - AY-3-819x PSG
;
; Copyright (c) 2021 Troy Schrapel
;
; This code is licensed under the MIT license
;
; https://github.com/visrealm/hbc-56
;
;
; Dependencies:
;  - hbc56.asm


; -------------------------
; Constants
; -------------------------
AY3891X_IO_ADDR = $40

AY3891X_PSG0 = $00
AY3891X_PSG1 = $04

; IO Ports
AY3891X_S0 = IO_PORT_BASE_ADDRESS | AY3891X_IO_ADDR | AY3891X_PSG0
AY3891X_S1 = IO_PORT_BASE_ADDRESS | AY3891X_IO_ADDR | AY3891X_PSG1

AY3891X_INACTIVE = $03
AY3891X_READ     = $02
AY3891X_WRITE    = $01
AY3891X_ADDR     = $00

AY3891X_S0_READ  = AY3891X_S0 | AY3891X_READ
AY3891X_S0_WRITE = AY3891X_S0 | AY3891X_WRITE
AY3891X_S0_ADDR  = AY3891X_S0 | AY3891X_ADDR

AY3891X_S1_READ  = AY3891X_S1 | AY3891X_READ
AY3891X_S1_WRITE = AY3891X_S1 | AY3891X_WRITE
AY3891X_S1_ADDR  = AY3891X_S1 | AY3891X_ADDR

; Registers
AY3891X_R0 = 0
AY3891X_R1 = 1
AY3891X_R2 = 2
AY3891X_R3 = 3
AY3891X_R4 = 4
AY3891X_R5 = 5
AY3891X_R6 = 6
AY3891X_R7 = 7
AY3891X_R8 = 8
AY3891X_R9 = 9
AY3891X_R10 = 10
AY3891X_R11 = 11
AY3891X_R12 = 12
AY3891X_R13 = 13
AY3891X_R14 = 14
AY3891X_R15 = 15
AY3891X_R16 = 16
AY3891X_R17 = 17

AY3891X_CHA = 0
AY3891X_CHB = 1
AY3891X_CHC = 2
AY3891X_CHN = 3

AY3891X_CHA_TONE_L   = AY3891X_R0
AY3891X_CHA_TONE_H   = AY3891X_R1
AY3891X_CHB_TONE_L   = AY3891X_R2
AY3891X_CHB_TONE_H   = AY3891X_R3
AY3891X_CHC_TONE_L   = AY3891X_R4
AY3891X_CHC_TONE_H   = AY3891X_R5
AY3891X_NOISE_GEN    = AY3891X_R6
AY3891X_ENABLES      = AY3891X_R7
AY3891X_CHA_AMPL     = AY3891X_R8
AY3891X_CHB_AMPL     = AY3891X_R9
AY3891X_CHC_AMPL     = AY3891X_R10
AY3891X_ENV_PERIOD_L = AY3891X_R11
AY3891X_ENV_PERIOD_H = AY3891X_R12
AY3891X_ENV_SHAPE    = AY3891X_R13
AY3891X_PORTA        = AY3891X_R14
AY3891X_PORTB        = AY3891X_R15

AY3891X_CLOCK_FREQ   = 2000000

!macro ay3891Write .dev, .reg, .val {

        lda #.reg
        sta IO_PORT_BASE_ADDRESS | AY3891X_IO_ADDR | AY3891X_ADDR | .dev
        lda #.val
        sta IO_PORT_BASE_ADDRESS | AY3891X_IO_ADDR | AY3891X_WRITE | .dev
}        


!macro ay3891WriteX .dev, .reg, .val {

        lda #.reg
        sta IO_PORT_BASE_ADDRESS | AY3891X_IO_ADDR | AY3891X_ADDR | .dev
        lda #.val
        sta IO_PORT_BASE_ADDRESS | AY3891X_IO_ADDR | AY3891X_WRITE | .dev
}

!macro ay3891WriteA .dev, .reg {
        pha
        lda #.reg
        sta IO_PORT_BASE_ADDRESS | AY3891X_IO_ADDR | AY3891X_ADDR | .dev
        pla
        sta IO_PORT_BASE_ADDRESS | AY3891X_IO_ADDR | AY3891X_WRITE | .dev
}

!macro ay3891PlayNote .dev, .chan, .freq {
        .val = AY3891X_CLOCK_FREQ / (16.0 * .freq)
        +ay3891Write .dev, AY3891X_CHA_TONE_L + (.chan * 2), <.val
        +ay3891Write .dev, AY3891X_CHA_TONE_H + (.chan * 2), >.val
}

!macro ay3891Stop .dev, .chan{
        +ay3891Write .dev, AY3891X_CHA_TONE_L + (.chan * 2), 0
        +ay3891Write .dev, AY3891X_CHA_TONE_H + (.chan * 2), 0
}

NOTE_A  = 440
NOTE_As = 466.16
NOTE_B  = 493.88
NOTE_C  = 523.25
NOTE_Cs = 554.37
NOTE_D  = 587.33
NOTE_Ds = 622.25
NOTE_E  = 659.25
NOTE_F  = 698.46
NOTE_Fs = 739.99
NOTE_G  = 783.99
NOTE_Gs = 830.61
NOTE_0  = 0


ay3891Init:
        +ay3891Write AY3891X_PSG0, AY3891X_ENABLES, $ff
        +ay3891Write AY3891X_PSG1, AY3891X_ENABLES, $ff


        +ay3891Write AY3891X_PSG0, AY3891X_CHA_AMPL, $00
        +ay3891Write AY3891X_PSG0, AY3891X_CHB_AMPL, $00
        +ay3891Write AY3891X_PSG0, AY3891X_CHC_AMPL, $00
        +ay3891Write AY3891X_PSG0, AY3891X_CHA_TONE_H, $00
        +ay3891Write AY3891X_PSG0, AY3891X_CHA_TONE_L, $00
        +ay3891Write AY3891X_PSG0, AY3891X_CHB_TONE_H, $00
        +ay3891Write AY3891X_PSG0, AY3891X_CHB_TONE_L, $00
        +ay3891Write AY3891X_PSG0, AY3891X_CHC_TONE_H, $00
        +ay3891Write AY3891X_PSG0, AY3891X_CHC_TONE_L, $00
        +ay3891Write AY3891X_PSG0, AY3891X_ENV_PERIOD_L, $00
        +ay3891Write AY3891X_PSG0, AY3891X_ENV_PERIOD_H, $00
        +ay3891Write AY3891X_PSG0, AY3891X_ENV_SHAPE, $00
        +ay3891Write AY3891X_PSG0, AY3891X_NOISE_GEN, $00

        +ay3891Write AY3891X_PSG1, AY3891X_CHA_AMPL, $00
        +ay3891Write AY3891X_PSG1, AY3891X_CHB_AMPL, $00
        +ay3891Write AY3891X_PSG1, AY3891X_CHC_AMPL, $00
        +ay3891Write AY3891X_PSG1, AY3891X_CHA_TONE_H, $00
        +ay3891Write AY3891X_PSG1, AY3891X_CHA_TONE_L, $00
        +ay3891Write AY3891X_PSG1, AY3891X_CHB_TONE_H, $00
        +ay3891Write AY3891X_PSG1, AY3891X_CHB_TONE_L, $00
        +ay3891Write AY3891X_PSG1, AY3891X_CHC_TONE_H, $00
        +ay3891Write AY3891X_PSG1, AY3891X_CHC_TONE_L, $00
        +ay3891Write AY3891X_PSG1, AY3891X_ENV_PERIOD_L, $00
        +ay3891Write AY3891X_PSG1, AY3891X_ENV_PERIOD_H, $00
        +ay3891Write AY3891X_PSG1, AY3891X_ENV_SHAPE, $00
        +ay3891Write AY3891X_PSG1, AY3891X_NOISE_GEN, $00
        rts
