.INCLUDE "apu.inc"
.INCLUDE "joypad.inc"
.INCLUDE "macros.inc"
.INCLUDE "oam.inc"
.INCLUDE "ppu.inc"

.IMPORT Func_ProcessFrame, Func_UpdateButtons
.IMPORT Ram_Cursor_oama, Ram_PpuTransfer_start
.IMPORTZP Zp_PpuTransferLen_u8
.IMPORTZP Zp_P1ButtonsHeld_u8, Zp_P1ButtonsPressed_u8
.IMPORTZP Zp_BaseName_u2, Zp_PpuMask_u8, Zp_ScrollX_u8, Zp_ScrollY_u8

.LINECONT +

;;;=========================================================================;;;

MENU_TOP_ROW    = 2
MENU_LEFT_COL   = 4
MENU_LABEL_COLS = 8

CURSOR_ROW_DUTY   = 0
CURSOR_ROW_VOLUME = 1
CURSOR_ROW_PERIOD = 2
NUM_CURSOR_ROWS   = 3

DUTY_1_8 = %00
DUTY_1_4 = %01
DUTY_1_2 = %10
DUTY_3_4 = %11
MAX_DUTY = %11

MAX_VOLUME = $f
MAX_PERIOD = $3ff

PPUADDR_DUTY_VALUE = (PPUADDR_NAME0 + SCREEN_WIDTH_TILES * (MENU_TOP_ROW + CURSOR_ROW_DUTY) + MENU_LEFT_COL + MENU_LABEL_COLS)
PPUADDR_VOLUME_VALUE = (PPUADDR_NAME0 + SCREEN_WIDTH_TILES * (MENU_TOP_ROW + CURSOR_ROW_VOLUME) + MENU_LEFT_COL + MENU_LABEL_COLS + 1)
PPUADDR_PERIOD_VALUE = (PPUADDR_NAME0 + SCREEN_WIDTH_TILES * (MENU_TOP_ROW + CURSOR_ROW_PERIOD) + MENU_LEFT_COL + MENU_LABEL_COLS + 1)

;;;=========================================================================;;;

.MACRO PPU_COPY_DIRECT dest, start, end
    .local @loop
    ldax #(dest)
    sta rPPUADDR
    stx rPPUADDR
    ldy #((end) - (start))
    ldx #0
    @loop:
    lda start, x
    sta rPPUDATA
    inx
    dey
    bne @loop
.ENDMACRO

;;;=========================================================================;;;

.BSS

Ram_CursorRow_u8: .res 1

Ram_Duty_u8: .res 1
Ram_Volume_u8: .res 1
Ram_Period_u16: .res 2

;;;=========================================================================;;;

.RODATA

Data_StrDuty_start:
    .byte "  Duty: 1/8"
Data_StrDuty_end:
Data_StrVolume_start:
    .byte "Volume: $0"
Data_StrVolume_end:
Data_StrPeriod_start:
    .byte "Period: $000"
Data_StrPeriod_end:

Data_Palettes_start:
    .byte $08  ; dark yellow
    .byte $19  ; medium green
    .byte $2a  ; green
    .byte $3a  ; pale green
    .byte $08
    .byte $11  ; medium azure
    .byte $21  ; light azure
    .byte $31  ; pale azure
    .byte $08
    .byte $16  ; medium red
    .byte $26  ; light red
    .byte $36  ; pale red
    .byte $08
    .byte $13  ; medium purple
    .byte $23  ; light purple
    .byte $33  ; pale purple
    .byte $08
    .byte $07  ; dark orange
    .byte $17  ; medium orange
    .byte $27  ; light orange
    .byte $08
    .byte $0c  ; dark cyan
    .byte $1c  ; medium cyan
    .byte $2c  ; light cyan
    .byte $08
    .byte $04  ; dark magenta
    .byte $14  ; medium magenta
    .byte $24  ; light magenta
    .byte $08
    .byte $02  ; dark blue
    .byte $12  ; medium blue
    .byte $22  ; light blue
Data_Palettes_end:

;;;=========================================================================;;;

.CODE

;;; @param a The hex digit, from 0-F.
;;; @return a The ASCII value.
.PROC Func_HexDigitToAscii
    cmp #$a
    bge @letter
    add #'0'
    rts
    @letter:
    add #('A' - 10)
    rts
.ENDPROC

.PROC Func_SetCh1Env
    lda Ram_Duty_u8
    clc
    ror a
    ror a
    ror a
    ora Ram_Volume_u8
    ora #%00110000
    sta rCH1ENV
    rts
.ENDPROC

.PROC Func_SetCh1Period
    lda Ram_Period_u16 + 0
    sta rCH1LOW
    lda Ram_Period_u16 + 1
    sta rCH1HIGH
    rts
.ENDPROC

.PROC Func_UpdateDuty
    ldx Zp_PpuTransferLen_u8
    lda #3
    sta Ram_PpuTransfer_start, x
    inx
    lda #>PPUADDR_DUTY_VALUE
    sta Ram_PpuTransfer_start, x
    inx
    lda #<PPUADDR_DUTY_VALUE
    sta Ram_PpuTransfer_start, x
    inx
    ;; Buffer first digit:
    lda Ram_Duty_u8
    cmp #DUTY_3_4
    beq @numerator3
    lda #'1'
    bne @doneFirstDigit  ; unconditional
    @numerator3:
    lda #'3'
    @doneFirstDigit:
    sta Ram_PpuTransfer_start, x
    inx
    ;; Buffer slash:
    lda #'/'
    sta Ram_PpuTransfer_start, x
    inx
    ;; Buffer second digit:
    lda Ram_Duty_u8
    cmp #DUTY_1_8
    beq @denominator8
    cmp #DUTY_1_2
    beq @denominator2
    lda #'4'
    bne @doneSecondDigit  ; unconditional
    @denominator8:
    lda #'8'
    bne @doneSecondDigit  ; unconditional
    @denominator2:
    lda #'2'
    @doneSecondDigit:
    sta Ram_PpuTransfer_start, x
    inx
    stx Zp_PpuTransferLen_u8
    ;; Update audio register:
    jmp Func_SetCh1Env
.ENDPROC

.PROC Func_UpdateVolume
    ldx Zp_PpuTransferLen_u8
    lda #1
    sta Ram_PpuTransfer_start, x
    inx
    lda #>PPUADDR_VOLUME_VALUE
    sta Ram_PpuTransfer_start, x
    inx
    lda #<PPUADDR_VOLUME_VALUE
    sta Ram_PpuTransfer_start, x
    inx
    ;; Buffer first (only) digit:
    lda Ram_Volume_u8
    jsr Func_HexDigitToAscii
    sta Ram_PpuTransfer_start, x
    inx
    stx Zp_PpuTransferLen_u8
    ;; Update audio register:
    jmp Func_SetCh1Env
.ENDPROC

.PROC Func_UpdatePeriod
    ldx Zp_PpuTransferLen_u8
    lda #3
    sta Ram_PpuTransfer_start, x
    inx
    lda #>PPUADDR_PERIOD_VALUE
    sta Ram_PpuTransfer_start, x
    inx
    lda #<PPUADDR_PERIOD_VALUE
    sta Ram_PpuTransfer_start, x
    inx
    ;; Buffer first digit:
    lda Ram_Period_u16 + 1
    jsr Func_HexDigitToAscii
    sta Ram_PpuTransfer_start, x
    inx
    ;; Buffer second digit:
    lda Ram_Period_u16 + 0
    .repeat 4
    lsr a
    .endrepeat
    jsr Func_HexDigitToAscii
    sta Ram_PpuTransfer_start, x
    inx
    ;; Buffer third digit:
    lda Ram_Period_u16 + 0
    and #$0f
    jsr Func_HexDigitToAscii
    sta Ram_PpuTransfer_start, x
    inx
    stx Zp_PpuTransferLen_u8
    ;; Update audio registers:
    jmp Func_SetCh1Period
.ENDPROC

.PROC Func_IncrementDuty
    lda Ram_Duty_u8
    cmp #MAX_DUTY
    blt @increment
    rts
    @increment:
    add #1
    sta Ram_Duty_u8
    jmp Func_UpdateDuty
.ENDPROC

.PROC Func_IncrementVolume
    lda Ram_Volume_u8
    cmp #MAX_VOLUME
    blt @increment
    rts
    @increment:
    add #1
    sta Ram_Volume_u8
    jmp Func_UpdateVolume
.ENDPROC

.PROC Func_IncrementPeriod
    ;; Store increment amount in XY.
    lda Zp_P1ButtonsHeld_u8
    and #BUTTON_A
    beq @not100
    ldx #$01
    ldy #$00
    beq @increment  ; unconditional
    @not100:
    lda Zp_P1ButtonsHeld_u8
    and #BUTTON_B
    beq @not10
    ldx #$00
    ldy #$10
    bne @increment  ; unconditional
    @not10:
    ldx #$00
    ldy #$01
    ;; Add XY to Ram_Period_u16.
    @increment:
    tya
    add Ram_Period_u16 + 0
    sta Ram_Period_u16 + 0
    txa
    adc Ram_Period_u16 + 1
    sta Ram_Period_u16 + 1
    ;; Clamp Ram_Period_u16 to MAX_PERIOD.
    lda Ram_Period_u16 + 1
    cmp #>(MAX_PERIOD + 1)
    blt @noClamp
    lda Ram_Period_u16 + 0
    cmp #<(MAX_PERIOD + 1)
    blt @noClamp
    lda #>MAX_PERIOD
    sta Ram_Period_u16 + 1
    lda #<MAX_PERIOD
    sta Ram_Period_u16 + 0
    @noClamp:
    jmp Func_UpdatePeriod
.ENDPROC

.PROC Func_IncrementCurrentRow
    lda Ram_CursorRow_u8
    cmp #CURSOR_ROW_DUTY
    jeq Func_IncrementDuty
    cmp #CURSOR_ROW_VOLUME
    jeq Func_IncrementVolume
    cmp #CURSOR_ROW_PERIOD
    jeq Func_IncrementPeriod
    rts
.ENDPROC

.PROC Func_DecrementDuty
    lda Ram_Duty_u8
    bne @decrement
    rts
    @decrement:
    sub #1
    sta Ram_Duty_u8
    jmp Func_UpdateDuty
.ENDPROC

.PROC Func_DecrementVolume
    lda Ram_Volume_u8
    bne @decrement
    rts
    @decrement:
    sub #1
    sta Ram_Volume_u8
    jmp Func_UpdateVolume
.ENDPROC

.PROC Func_DecrementPeriod
    ;; Store decrement amount in XY.
    lda Zp_P1ButtonsHeld_u8
    and #BUTTON_A
    beq @not100
    ldx #$01
    ldy #$00
    beq @compare  ; unconditional
    @not100:
    lda Zp_P1ButtonsHeld_u8
    and #BUTTON_B
    beq @not10
    ldx #$00
    ldy #$10
    bne @compare  ; unconditional
    @not10:
    ldx #$00
    ldy #$01
    ;; If XY >= Ram_Period_u16, set Ram_Period_u16 to zero.
    @compare:
    txa
    cmp Ram_Period_u16 + 1
    blt @noClamp
    tya
    cmp Ram_Period_u16 + 0
    blt @noClamp
    lda #0
    sta Ram_Period_u16 + 0
    sta Ram_Period_u16 + 1
    jmp Func_UpdatePeriod
    @noClamp:
    ;; Subtract XY from Ram_Period_u16.
    tya
    eor #$ff
    sec
    adc Ram_Period_u16 + 0
    sta Ram_Period_u16 + 0
    txa
    eor #$ff
    adc Ram_Period_u16 + 1
    sta Ram_Period_u16 + 1
    jmp Func_UpdatePeriod
.ENDPROC

.PROC Func_DecrementCurrentRow
    lda Ram_CursorRow_u8
    cmp #CURSOR_ROW_DUTY
    jeq Func_DecrementDuty
    cmp #CURSOR_ROW_VOLUME
    jeq Func_DecrementVolume
    cmp #CURSOR_ROW_PERIOD
    jeq Func_DecrementPeriod
    rts
.ENDPROC

;;;=========================================================================;;;

.CODE

;;; @prereq Rendering is disabled.
.EXPORT Main
.PROC Main
    ;; Show only nametable 0 on screen.
    lda #0
    sta Zp_ScrollX_u8
    sta Zp_ScrollY_u8
    sta Zp_BaseName_u2
    ;; Enable rendering for next frame.
    lda #PPUMASK_ALL
    sta Zp_PpuMask_u8
_ClearNametable:
    ;; Fill nametable 0 with ' '.
    bit rPPUSTATUS  ; Reset the write-twice latch for rPPUADDR.
    ldax #PPUADDR_NAME0
    sta rPPUADDR
    stx rPPUADDR
    lda #' '
    ldy #SCREEN_HEIGHT_TILES
    @outerLoop:
    ldx #SCREEN_WIDTH_TILES
    @innerLoop:
    sta rPPUDATA
    dex
    bne @innerLoop
    dey
    bne @outerLoop
    ;; Fill attribute table 0.  (rPPUADDR is already set up for this.)
    lda #%11100100
    ldx #(ATTR_WIDTH * ATTR_HEIGHT)
    @attrLoop:
    sta rPPUDATA
    dex
    bne @attrLoop
_InitNametable:
    PPU_COPY_DIRECT (PPUADDR_NAME0 + SCREEN_WIDTH_TILES * 2 + 4), \
                    Data_StrDuty_start, Data_StrDuty_end
    PPU_COPY_DIRECT (PPUADDR_NAME0 + SCREEN_WIDTH_TILES * 3 + 4), \
                    Data_StrVolume_start, Data_StrVolume_end
    PPU_COPY_DIRECT (PPUADDR_NAME0 + SCREEN_WIDTH_TILES * 4 + 4), \
                    Data_StrPeriod_start, Data_StrPeriod_end
_InitPalettes:
    ldax #PPUADDR_PALETTES
    sta rPPUADDR
    stx rPPUADDR
    ldy #(Data_Palettes_end - Data_Palettes_start)
    ldx #0
    @loop:
    lda Data_Palettes_start, x
    sta rPPUDATA
    inx
    dey
    bne @loop
_InitOam:
    lda #0
    sta Ram_Cursor_oama + OAMA::Flags
    lda #'>'
    sta Ram_Cursor_oama + OAMA::Tile
    lda #$10
    sta Ram_Cursor_oama + OAMA::XPos
    lda #$18
    sta Ram_Cursor_oama + OAMA::YPos
_InitApu:
    lda #APUCTRL_PULSE1
    sta rAPUCTRL
_GameLoop:
    jsr Func_UpdateButtons
_CheckButtonDown:
    lda #BUTTON_DOWN
    bit Zp_P1ButtonsPressed_u8
    beq @notPressed
    lda Ram_CursorRow_u8
    add #1
    cmp #NUM_CURSOR_ROWS
    blt @noWrap
    lda #0
    @noWrap:
    sta Ram_CursorRow_u8
    @notPressed:
_CheckButtonUp:
    lda #BUTTON_UP
    bit Zp_P1ButtonsPressed_u8
    beq @notPressed
    lda Ram_CursorRow_u8
    sub #1
    bpl @noWrap
    lda #(NUM_CURSOR_ROWS - 1)
    @noWrap:
    sta Ram_CursorRow_u8
    @notPressed:
_CheckButtonRight:
    lda #BUTTON_RIGHT
    bit Zp_P1ButtonsPressed_u8
    beq @notPressed
    jsr Func_IncrementCurrentRow
    @notPressed:
_CheckButtonLeft:
    lda #BUTTON_LEFT
    bit Zp_P1ButtonsPressed_u8
    beq @notPressed
    jsr Func_DecrementCurrentRow
    @notPressed:
_UpdateCursor:
    lda Ram_CursorRow_u8
    asl a
    asl a
    asl a
    adc #$10
    sta Ram_Cursor_oama + OAMA::YPos
_DrawFrame:
    jsr Func_ProcessFrame
    jmp _GameLoop
.ENDPROC

;;;=========================================================================;;;
