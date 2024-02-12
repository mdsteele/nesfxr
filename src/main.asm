.INCLUDE "apu.inc"
.INCLUDE "field.inc"
.INCLUDE "joypad.inc"
.INCLUDE "macros.inc"
.INCLUDE "oam.inc"
.INCLUDE "ppu.inc"

.IMPORT Func_DecrementValueOfCurrentField
.IMPORT Func_DrawCursor
.IMPORT Func_IncrementValueOfCurrentField
.IMPORT Func_Noop
.IMPORT Func_ProcessFrame
.IMPORT Func_UpdateButtons
.IMPORT Ram_ChannelBuzz_bool_arr
.IMPORT Ram_ChannelDecay_bool_arr
.IMPORT Ram_ChannelPeriod_u16_0_arr
.IMPORT Ram_ChannelPeriod_u16_1_arr
.IMPORT Ram_ChannelVolume_u8_arr
.IMPORTZP Zp_BaseName_u2
.IMPORTZP Zp_P1ButtonsPressed_u8
.IMPORTZP Zp_PpuMask_u8
.IMPORTZP Zp_ScrollX_u8
.IMPORTZP Zp_ScrollY_u8

;;;=========================================================================;;;

.ZEROPAGE

.EXPORTZP Zp_Cursor_eField
Zp_Cursor_eField: .res 1

.EXPORTZP Zp_Ch1Duty_eDuty
Zp_Ch1Duty_eDuty: .res 1
.EXPORTZP Zp_Ch1SweepPeriod_u8
Zp_Ch1SweepPeriod_u8: .res 1
.EXPORTZP Zp_Ch1SweepShift_i8
Zp_Ch1SweepShift_i8: .res 1
.EXPORTZP Zp_Ch1VibratoDepth_u8
Zp_Ch1VibratoDepth_u8: .res 1

;;;=========================================================================;;;

.BSS

Ram_VibratoPhase_u8: .res 1

;;;=========================================================================;;;

.RODATA

.PROC Data_ScreenTiles_arr
    .byte "+------------------------------+"
    .byte "|                              |"
    .byte "| PULSE 1 CHANNEL              |"
    .byte "|      Pulse duty: 1/8         |"
    .byte "|      Env volume: $0          |"
    .byte "|       Env decay: NO          |"
    .byte "|     Sweep shift: OFF         |"
    .byte "|    Sweep period: 0           |"
    .byte "|     Tone period: $000        |"
    .byte "|   Vibrato depth: $00         |"
    .byte "|                              |"
    .byte "| PULSE 2 CHANNEL       (TODO) |"
    .byte "|                              |"
    .byte "| TRIANGLE CHANNEL             |"
    .byte "|     Tone period: $000 (TODO) |"
    .byte "|   Vibrato depth: $00  (TODO) |"
    .byte "|                              |"
    .byte "| NOISE CHANNEL                |"
    .byte "|      Env volume: $0          |"
    .byte "|       Env decay: NO          |"
    .byte "|    Noise period: $0          |"
    .byte "|      Noise buzz: NO          |"
    .byte "|                              |"
    .byte "|                              |"
    .byte "|                              |"
    .byte "|                              |"
    .byte "|                              |"
    .byte "|                              |"
    .byte "|                              |"
    .byte "+------------------------------+"
.ENDPROC

Data_Palettes_start:
    .byte $1d  ; black
    .byte $19  ; medium green
    .byte $2a  ; green
    .byte $30  ; white
    .byte $1d
    .byte $11  ; medium azure
    .byte $21  ; light azure
    .byte $31  ; pale azure
    .byte $1d
    .byte $16  ; medium red
    .byte $26  ; light red
    .byte $36  ; pale red
    .byte $1d
    .byte $13  ; medium purple
    .byte $23  ; light purple
    .byte $33  ; pale purple
    .byte $1d
    .byte $07  ; dark orange
    .byte $17  ; medium orange
    .byte $27  ; light orange
    .byte $1d
    .byte $0c  ; dark cyan
    .byte $1c  ; medium cyan
    .byte $2c  ; light cyan
    .byte $1d
    .byte $04  ; dark magenta
    .byte $14  ; medium magenta
    .byte $24  ; light magenta
    .byte $1d
    .byte $02  ; dark blue
    .byte $12  ; medium blue
    .byte $22  ; light blue
Data_Palettes_end:

;;;=========================================================================;;;

.CODE

;;; @param X The eChannel.
.EXPORT Func_SetChannelEnv
.PROC Func_SetChannelEnv
    lda _JumpTable_ptr_0_arr, x
    sta T0
    lda _JumpTable_ptr_1_arr, x
    sta T1
    jmp (T1T0)
.REPEAT 2, table
    D_TABLE_LO table, _JumpTable_ptr_0_arr
    D_TABLE_HI table, _JumpTable_ptr_1_arr
    D_TABLE eChannel
    d_entry table, Pulse1,   Func_SetCh1Env
    d_entry table, Pulse2,   Func_Noop
    d_entry table, Triangle, Func_Noop
    d_entry table, Noise,    Func_SetChNEnv
    d_entry table, Dmc,      Func_Noop
    D_END
.ENDREPEAT
.ENDPROC

.EXPORT Func_SetCh1Env
.PROC Func_SetCh1Env
    lda Zp_Ch1Duty_eDuty
    clc
    ror a
    ror a
    ror a
    sta T0  ; duty
    lda Ram_ChannelDecay_bool_arr + eChannel::Pulse1
    and #%00010000
    eor #%00010000
    ora T0  ; duty
    ora Ram_ChannelVolume_u8_arr + eChannel::Pulse1
    ora #%00100000
    sta rCH1ENV
    rts
.ENDPROC

.PROC Func_SetChNEnv
    lda Ram_ChannelDecay_bool_arr + eChannel::Noise
    and #%00010000
    eor #%00010000
    ora Ram_ChannelVolume_u8_arr + eChannel::Noise
    ora #%00100000
    sta rCHNENV
    rts
.ENDPROC

.EXPORT Func_SetCh1Sweep
.PROC Func_SetCh1Sweep
    lda Zp_Ch1SweepShift_i8
    beq _SetSweep
    bpl _Pos
_Neg:
    and #%00001111
    bpl _NonZero  ; unconditional
_Pos:
    lda #8
    sub Zp_Ch1SweepShift_i8
_NonZero:
    sta T0  ; shift
    lda Zp_Ch1SweepPeriod_u8
    mul #$10
    ora T0  ; shift
    ora #%10000000
_SetSweep:
    sta rCH1SWEEP
    rts
.ENDPROC

;;; @param X The eChannel.
.EXPORT Func_SetChannelPeriod
.PROC Func_SetChannelPeriod
    lda _JumpTable_ptr_0_arr, x
    sta T0
    lda _JumpTable_ptr_1_arr, x
    sta T1
    jmp (T1T0)
.REPEAT 2, table
    D_TABLE_LO table, _JumpTable_ptr_0_arr
    D_TABLE_HI table, _JumpTable_ptr_1_arr
    D_TABLE eChannel
    d_entry table, Pulse1,   Func_SetCh1Period
    d_entry table, Pulse2,   Func_Noop
    d_entry table, Triangle, Func_Noop
    d_entry table, Noise,    Func_SetChNPeriod
    d_entry table, Dmc,      Func_Noop
    D_END
.ENDREPEAT
.ENDPROC

.PROC Func_SetCh1Period
    lda Ram_ChannelPeriod_u16_0_arr + eChannel::Pulse1
    sta rCH1LOW
    lda Ram_ChannelPeriod_u16_1_arr + eChannel::Pulse1
    ora #%11111000
    sta rCH1HIGH
    rts
.ENDPROC

.PROC Func_SetChNPeriod
    lda Ram_ChannelBuzz_bool_arr + eChannel::Noise
    and #%10000000
    ora Ram_ChannelPeriod_u16_0_arr + eChannel::Noise
    sta rCHNLOW
    lda #%11111000
    sta rCHNHIGH
    rts
.ENDPROC

.PROC Func_RestartSound
    jsr Func_SetCh1Env
    jsr Func_SetCh1Sweep
    jsr Func_SetCh1Period
    jsr Func_SetChNEnv
    jsr Func_SetChNPeriod
    rts
.ENDPROC

;;;=========================================================================;;;

.CODE

.PROC Func_AdvanceVibrato
    lda Zp_Ch1VibratoDepth_u8
    beq @return
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
    add Ram_ChannelPeriod_u16_0_arr + eChannel::Pulse1
    sta rCH1LOW
    @return:
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
    lda #%00000000
    ldx #(ATTR_WIDTH * ATTR_HEIGHT)
    @attrLoop:
    sta Hw_PpuData_rw
    dex
    bne @attrLoop
_InitNametable:
    ldax #Data_ScreenTiles_arr
    stax T1T0
    ldax #PPUADDR_NAME0
    sta Hw_PpuAddr_w2
    stx Hw_PpuAddr_w2
    ldy #0
    @loop:
    lda (T1T0), y
    sta Hw_PpuData_rw
    inc T0
    bne @inc
    inc T1
    @inc:
    lda T1
    cmp #>(Data_ScreenTiles_arr + .sizeof(Data_ScreenTiles_arr))
    bne @loop
    lda T0
    cmp #<(Data_ScreenTiles_arr + .sizeof(Data_ScreenTiles_arr))
    bne @loop
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
    lda #bApuStatus::Pulse1 | bApuStatus::Noise
    sta Hw_ApuStatus_rw
    jsr Func_RestartSound
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
_CheckButtonStart:
    lda #bJoypad::Start
    bit Zp_P1ButtonsPressed_u8
    beq @notPressed
    jsr Func_RestartSound
    @notPressed:
_DrawFrame:
    jsr Func_DrawCursor
    jsr Func_ProcessFrame
    jsr Func_AdvanceVibrato
    jmp _GameLoop
.ENDPROC

;;;=========================================================================;;;
