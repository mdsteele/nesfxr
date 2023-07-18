.INCLUDE "apu.inc"
.INCLUDE "field.inc"
.INCLUDE "joypad.inc"
.INCLUDE "macros.inc"
.INCLUDE "oam.inc"
.INCLUDE "ppu.inc"

.IMPORT Func_DecrementValueOfCurrentField
.IMPORT Func_DrawCursor
.IMPORT Func_IncrementValueOfCurrentField
.IMPORT Func_ProcessFrame
.IMPORT Func_UpdateButtons
.IMPORTZP Zp_BaseName_u2
.IMPORTZP Zp_P1ButtonsPressed_u8
.IMPORTZP Zp_PpuMask_u8
.IMPORTZP Zp_ScrollX_u8
.IMPORTZP Zp_ScrollY_u8

;;;=========================================================================;;;

.MACRO PPU_COPY_DIRECT Dest, Start, End
    .local @loop
    ldax #(Dest)
    sta Hw_PpuAddr_w2
    stx Hw_PpuAddr_w2
    ldy #((End) - (Start))
    ldx #0
    @loop:
    lda Start, x
    sta Hw_PpuData_rw
    inx
    dey
    bne @loop
.ENDMACRO

;;;=========================================================================;;;

.ZEROPAGE

.EXPORTZP Zp_Cursor_eField
Zp_Cursor_eField: .res 1

.EXPORTZP Zp_Ch1Duty_eDuty
Zp_Ch1Duty_eDuty: .res 1
.EXPORTZP Zp_Ch1Volume_u8
Zp_Ch1Volume_u8: .res 1
.EXPORTZP Zp_Ch1Period_u16
Zp_Ch1Period_u16: .res 2
.EXPORTZP Zp_Ch1VibratoDepth_u8
Zp_Ch1VibratoDepth_u8: .res 1

;;;=========================================================================;;;

.BSS

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
.EXPORT Func_HexDigitToAscii
.PROC Func_HexDigitToAscii
    cmp #$a
    bge @letter
    add #'0'
    rts
    @letter:
    add #('A' - 10)
    rts
.ENDPROC

.EXPORT Func_SetCh1Env
.PROC Func_SetCh1Env
    lda Zp_Ch1Duty_eDuty
    clc
    ror a
    ror a
    ror a
    ora Zp_Ch1Volume_u8
    ora #%00110000
    sta rCH1ENV
    rts
.ENDPROC

.EXPORT Func_SetCh1Period
.PROC Func_SetCh1Period
    lda Zp_Ch1Period_u16 + 0
    sta rCH1LOW
    sta Ram_PeriodLo_u8
    lda Zp_Ch1Period_u16 + 1
    sta rCH1HIGH
    rts
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
    lda Zp_Ch1VibratoDepth_u8
    jmp @finish
    @minus:
    lda Zp_Ch1VibratoDepth_u8
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
_DrawFrame:
    jsr Func_DrawCursor
    jsr Func_ProcessFrame
    jsr Func_AdvanceVibrato
    jmp _GameLoop
.ENDPROC

;;;=========================================================================;;;
