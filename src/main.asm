.INCLUDE "apu.inc"
.INCLUDE "field.inc"
.INCLUDE "joypad.inc"
.INCLUDE "macros.inc"
.INCLUDE "oam.inc"
.INCLUDE "ppu.inc"

.IMPORT Data_FieldTileRow_u8
.IMPORT Func_ProcessFrame
.IMPORT Func_StartFieldValuePpuTransfer
.IMPORT Func_UpdateButtons
.IMPORT Ram_Cursor_sObj
.IMPORT Ram_PpuTransfer_start
.IMPORTZP Zp_BaseName_u2
.IMPORTZP Zp_P1ButtonsHeld_u8
.IMPORTZP Zp_P1ButtonsPressed_u8
.IMPORTZP Zp_PpuMask_u8
.IMPORTZP Zp_ScrollX_u8
.IMPORTZP Zp_ScrollY_u8

;;;=========================================================================;;;

MENU_TOP_ROW    = 2
MENU_LEFT_COL   = 4
MENU_LABEL_COLS = 9

DUTY_1_8 = %00
DUTY_1_4 = %01
DUTY_1_2 = %10
DUTY_3_4 = %11
MAX_DUTY = %11

MAX_VOLUME = $f
MAX_PERIOD = $3ff

;;;=========================================================================;;;

.MACRO PPU_COPY_DIRECT dest, start, end
    .local @loop
    ldax #(dest)
    sta Hw_PpuAddr_w2
    stx Hw_PpuAddr_w2
    ldy #((end) - (start))
    ldx #0
    @loop:
    lda start, x
    sta Hw_PpuData_rw
    inx
    dey
    bne @loop
.ENDMACRO

;;;=========================================================================;;;

.ZEROPAGE

Zp_Cursor_eField: .res 1

;;;=========================================================================;;;

.BSS

Ram_Duty_u8: .res 1
Ram_Volume_u8: .res 1
Ram_Period_u16: .res 2
Ram_VibratoDepth_u8: .res 1

Ram_PeriodLo_u8: .res 1
Ram_VibratoPhase_u8: .res 1

;;;=========================================================================;;;

.RODATA

Data_StrDuty_start:
    .byte "   Duty: 1/8"
Data_StrDuty_end:
Data_StrVolume_start:
    .byte " Volume: $0"
Data_StrVolume_end:
Data_StrPeriod_start:
    .byte " Period: $000"
Data_StrPeriod_end:
Data_StrVibrato_start:
    .byte "Vibrato: $00"
Data_StrVibrato_end:

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

;;; @param A The hex digit, from 0-F.
;;; @return A The ASCII value.
;;; @preserve X, Y, T0+
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
    sta Ram_PeriodLo_u8
    lda Ram_Period_u16 + 1
    sta rCH1HIGH
    rts
.ENDPROC

.PROC Func_UpdateDuty
    ldy #eField::Ch1Duty  ; param: eField
    lda #3  ; param: transfer length
    jsr Func_StartFieldValuePpuTransfer  ; returns X
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
    ;; Update audio register:
    jmp Func_SetCh1Env
.ENDPROC

.PROC Func_UpdateVolume
    ldy #eField::Ch1Volume  ; param: eField
    lda #1  ; param: transfer length
    jsr Func_StartFieldValuePpuTransfer  ; returns X
    ;; Buffer first (only) digit:
    lda Ram_Volume_u8
    jsr Func_HexDigitToAscii  ; preserves X
    sta Ram_PpuTransfer_start, x
    ;; Update audio register:
    jmp Func_SetCh1Env
.ENDPROC

.PROC Func_UpdatePeriod
    ldy #eField::Ch1Period  ; param: eField
    lda #3  ; param: transfer length
    jsr Func_StartFieldValuePpuTransfer  ; returns X
    ;; Buffer first digit:
    lda Ram_Period_u16 + 1
    jsr Func_HexDigitToAscii  ; preserves X
    sta Ram_PpuTransfer_start, x
    inx
    ;; Buffer second digit:
    lda Ram_Period_u16 + 0
    div #$10
    jsr Func_HexDigitToAscii  ; preserves X
    sta Ram_PpuTransfer_start, x
    inx
    ;; Buffer third digit:
    lda Ram_Period_u16 + 0
    and #$0f
    jsr Func_HexDigitToAscii  ; preserves X
    sta Ram_PpuTransfer_start, x
    ;; Update audio registers:
    jmp Func_SetCh1Period
.ENDPROC

.PROC Func_UpdateVibrato
    ldy #eField::Ch1Vibrato  ; param: eField
    lda #2  ; param: transfer length
    jsr Func_StartFieldValuePpuTransfer  ; returns X
    ;; Buffer first digit:
    lda Ram_VibratoDepth_u8
    div #$10
    jsr Func_HexDigitToAscii  ; preserves X
    sta Ram_PpuTransfer_start, x
    inx
    ;; Buffer second digit:
    lda Ram_VibratoDepth_u8
    and #$0f
    jsr Func_HexDigitToAscii  ; preserves X
    sta Ram_PpuTransfer_start, x
    rts
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
    and #bJoypad::AButton
    beq @not100
    ldx #$01
    ldy #$00
    beq @increment  ; unconditional
    @not100:
    lda Zp_P1ButtonsHeld_u8
    and #bJoypad::BButton
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

.PROC Func_IncrementVibrato
    lda Ram_VibratoDepth_u8
    bne @nonzero
    inc Ram_VibratoDepth_u8
    jmp Func_UpdateVibrato
    @nonzero:
    bpl @shift
    rts
    @shift:
    asl Ram_VibratoDepth_u8
    jmp Func_UpdateVibrato
.ENDPROC

.PROC Func_IncrementValueOfCurrentField
    ldy Zp_Cursor_eField
    lda _JumpTable_ptr_0_arr, y
    sta T0
    lda _JumpTable_ptr_1_arr, y
    sta T1
    jmp (T1T0)
.REPEAT 2, table
    D_TABLE_LO table, _JumpTable_ptr_0_arr
    D_TABLE_HI table, _JumpTable_ptr_1_arr
    D_TABLE eField
    d_entry table, Ch1Duty,    Func_IncrementDuty
    d_entry table, Ch1Volume,  Func_IncrementVolume
    d_entry table, Ch1Period,  Func_IncrementPeriod
    d_entry table, Ch1Vibrato, Func_IncrementVibrato
    D_END
.ENDREPEAT
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
    and #bJoypad::AButton
    beq @not100
    ldx #$01
    ldy #$00
    beq @compare  ; unconditional
    @not100:
    lda Zp_P1ButtonsHeld_u8
    and #bJoypad::BButton
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

.PROC Func_DecrementVibrato
    lsr Ram_VibratoDepth_u8
    jmp Func_UpdateVibrato
.ENDPROC

.PROC Func_DecrementValueOfCurrentField
    ldy Zp_Cursor_eField
    lda _JumpTable_ptr_0_arr, y
    sta T0
    lda _JumpTable_ptr_1_arr, y
    sta T1
    jmp (T1T0)
.REPEAT 2, table
    D_TABLE_LO table, _JumpTable_ptr_0_arr
    D_TABLE_HI table, _JumpTable_ptr_1_arr
    D_TABLE eField
    d_entry table, Ch1Duty,    Func_DecrementDuty
    d_entry table, Ch1Volume,  Func_DecrementVolume
    d_entry table, Ch1Period,  Func_DecrementPeriod
    d_entry table, Ch1Vibrato, Func_DecrementVibrato
    D_END
.ENDREPEAT
.ENDPROC

;;;=========================================================================;;;

.CODE

.PROC Func_AdvanceVibrato
    lda Ram_VibratoPhase_u8
    add #1
    and #%11
    sta Ram_VibratoPhase_u8
    cmp #1
    beq @plus
    cmp #3
    beq @minus
    lda #0
    jmp @finish
    @plus:
    lda Ram_VibratoDepth_u8
    jmp @finish
    @minus:
    lda Ram_VibratoDepth_u8
    eor #$ff
    add #1
    @finish:
    add Ram_PeriodLo_u8
    sta rCH1LOW
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
    lda #bPpuMask::ObjAll | bPpuMask::BgAll
    sta Zp_PpuMask_u8
_ClearNametable:
    ;; Fill nametable 0 with ' '.
    bit Hw_PpuStatus_ro  ; Reset the write-twice latch for Hw_PpuAddr_w2.
    ldax #PPUADDR_NAME0
    sta Hw_PpuAddr_w2
    stx Hw_PpuAddr_w2
    lda #' '
    ldy #SCREEN_HEIGHT_TILES
    @outerLoop:
    ldx #SCREEN_WIDTH_TILES
    @innerLoop:
    sta Hw_PpuData_rw
    dex
    bne @innerLoop
    dey
    bne @outerLoop
    ;; Fill attribute table 0.  (Hw_PpuAddr_w2 is already set up for this.)
    lda #%11100100
    ldx #(ATTR_WIDTH * ATTR_HEIGHT)
    @attrLoop:
    sta Hw_PpuData_rw
    dex
    bne @attrLoop
_InitNametable:
    .linecont +
    PPU_COPY_DIRECT (PPUADDR_NAME0 + SCREEN_WIDTH_TILES * 2 + 4), \
                    Data_StrDuty_start, Data_StrDuty_end
    PPU_COPY_DIRECT (PPUADDR_NAME0 + SCREEN_WIDTH_TILES * 3 + 4), \
                    Data_StrVolume_start, Data_StrVolume_end
    PPU_COPY_DIRECT (PPUADDR_NAME0 + SCREEN_WIDTH_TILES * 4 + 4), \
                    Data_StrPeriod_start, Data_StrPeriod_end
    PPU_COPY_DIRECT (PPUADDR_NAME0 + SCREEN_WIDTH_TILES * 5 + 4), \
                    Data_StrVibrato_start, Data_StrVibrato_end
    .linecont -
_InitPalettes:
    ldax #PPUADDR_PALETTES
    sta Hw_PpuAddr_w2
    stx Hw_PpuAddr_w2
    ldy #(Data_Palettes_end - Data_Palettes_start)
    ldx #0
    @loop:
    lda Data_Palettes_start, x
    sta Hw_PpuData_rw
    inx
    dey
    bne @loop
_InitOam:
    lda #0
    sta Ram_Cursor_sObj + sObj::Flags_bObj
    lda #'>'
    sta Ram_Cursor_sObj + sObj::Tile_u8
    lda #$10
    sta Ram_Cursor_sObj + sObj::XPos_u8
    lda #$18
    sta Ram_Cursor_sObj + sObj::YPos_u8
_InitApu:
    lda #bApuStatus::Pulse1
    sta Hw_ApuStatus_rw
_GameLoop:
    jsr Func_UpdateButtons
_CheckButtonDown:
    lda #bJoypad::Down
    bit Zp_P1ButtonsPressed_u8
    beq @done
    inc Zp_Cursor_eField
    lda Zp_Cursor_eField
    cmp #eField::NUM_VALUES
    blt @done
    lda #0
    sta Zp_Cursor_eField
    @done:
_CheckButtonUp:
    lda #bJoypad::Up
    bit Zp_P1ButtonsPressed_u8
    beq @done
    lda Zp_Cursor_eField
    bne @noWrap
    lda #eField::NUM_VALUES
    @noWrap:
    sub #1
    sta Zp_Cursor_eField
    @done:
_CheckButtonRight:
    lda #bJoypad::Right
    bit Zp_P1ButtonsPressed_u8
    beq @notPressed
    jsr Func_IncrementValueOfCurrentField
    @notPressed:
_CheckButtonLeft:
    lda #bJoypad::Left
    bit Zp_P1ButtonsPressed_u8
    beq @notPressed
    jsr Func_DecrementValueOfCurrentField
    @notPressed:
_UpdateCursor:
    ldx Zp_Cursor_eField
    lda Data_FieldTileRow_u8, x
    mul #kTileHeightPx
    sta Ram_Cursor_sObj + sObj::YPos_u8
_DrawFrame:
    jsr Func_ProcessFrame
    jsr Func_AdvanceVibrato
    jmp _GameLoop
.ENDPROC

;;;=========================================================================;;;
