.INCLUDE "apu.inc"
.INCLUDE "field.inc"
.INCLUDE "macros.inc"
.INCLUDE "oam.inc"
.INCLUDE "ppu.inc"

.IMPORT Func_DecrementDuty
.IMPORT Func_DecrementPeriod
.IMPORT Func_DecrementSweepPeriod
.IMPORT Func_DecrementSweepShift
.IMPORT Func_DecrementVibrato
.IMPORT Func_DecrementVolume
.IMPORT Func_IncrementDuty
.IMPORT Func_IncrementPeriod
.IMPORT Func_IncrementSweepPeriod
.IMPORT Func_IncrementSweepShift
.IMPORT Func_IncrementVibrato
.IMPORT Func_IncrementVolume
.IMPORT Func_ToggleDecay
.IMPORT Ram_Cursor_sObj
.IMPORT Ram_PpuTransfer_start
.IMPORTZP Zp_Cursor_eField
.IMPORTZP Zp_PpuTransferLen_u8

;;;=========================================================================;;;

.RODATA

.PROC Data_FieldTileRow_u8_arr
    D_ENUM eField
    d_byte Ch1Duty,        3
    d_byte Ch1Volume,      4
    d_byte Ch1Decay,       5
    d_byte Ch1SweepShift,  6
    d_byte Ch1SweepPeriod, 7
    d_byte Ch1Period,      8
    d_byte Ch1Vibrato,     9
    d_byte NoiseVolume,   18
    d_byte NoiseDecay,    19
    d_byte NoisePeriod,   20
    D_END
.ENDPROC

.PROC Data_FieldValueTileCol_u8_arr
    D_ENUM eField
    d_byte Ch1Duty,        19
    d_byte Ch1Volume,      20
    d_byte Ch1Decay,       19
    d_byte Ch1SweepShift,  19
    d_byte Ch1SweepPeriod, 19
    d_byte Ch1Period,      20
    d_byte Ch1Vibrato,     20
    d_byte NoiseVolume,    20
    d_byte NoiseDecay,     19
    d_byte NoisePeriod,    20
    D_END
.ENDPROC

.PROC Data_FieldChannel_eChannel_arr
    D_ENUM eField
    d_byte Ch1Duty,        eChannel::Pulse1
    d_byte Ch1Volume,      eChannel::Pulse1
    d_byte Ch1Decay,       eChannel::Pulse1
    d_byte Ch1SweepShift,  eChannel::Pulse1
    d_byte Ch1SweepPeriod, eChannel::Pulse1
    d_byte Ch1Period,      eChannel::Pulse1
    d_byte Ch1Vibrato,     eChannel::Pulse1
    d_byte NoiseVolume,    eChannel::Noise
    d_byte NoiseDecay,     eChannel::Noise
    d_byte NoisePeriod,    eChannel::Noise
    D_END
.ENDPROC

;;;=========================================================================;;;

.CODE

.EXPORT Func_IncrementValueOfCurrentField
.PROC Func_IncrementValueOfCurrentField
    ldy Zp_Cursor_eField
    ldx Data_FieldChannel_eChannel_arr, y  ; param: eChannel
    lda _JumpTable_ptr_0_arr, y
    sta T0
    lda _JumpTable_ptr_1_arr, y
    sta T1
    jmp (T1T0)
.REPEAT 2, table
    D_TABLE_LO table, _JumpTable_ptr_0_arr
    D_TABLE_HI table, _JumpTable_ptr_1_arr
    D_TABLE eField
    d_entry table, Ch1Duty,        Func_IncrementDuty
    d_entry table, Ch1Volume,      Func_IncrementVolume
    d_entry table, Ch1Decay,       Func_ToggleDecay
    d_entry table, Ch1SweepShift,  Func_IncrementSweepShift
    d_entry table, Ch1SweepPeriod, Func_IncrementSweepPeriod
    d_entry table, Ch1Period,      Func_IncrementPeriod
    d_entry table, Ch1Vibrato,     Func_IncrementVibrato
    d_entry table, NoiseVolume,    Func_IncrementVolume
    d_entry table, NoiseDecay,     Func_ToggleDecay
    d_entry table, NoisePeriod,    Func_IncrementPeriod
    D_END
.ENDREPEAT
.ENDPROC

.EXPORT Func_DecrementValueOfCurrentField
.PROC Func_DecrementValueOfCurrentField
    ldy Zp_Cursor_eField
    ldx Data_FieldChannel_eChannel_arr, y  ; param: eChannel
    lda _JumpTable_ptr_0_arr, y
    sta T0
    lda _JumpTable_ptr_1_arr, y
    sta T1
    jmp (T1T0)
.REPEAT 2, table
    D_TABLE_LO table, _JumpTable_ptr_0_arr
    D_TABLE_HI table, _JumpTable_ptr_1_arr
    D_TABLE eField
    d_entry table, Ch1Duty,        Func_DecrementDuty
    d_entry table, Ch1Volume,      Func_DecrementVolume
    d_entry table, Ch1Decay,       Func_ToggleDecay
    d_entry table, Ch1SweepShift,  Func_DecrementSweepShift
    d_entry table, Ch1SweepPeriod, Func_DecrementSweepPeriod
    d_entry table, Ch1Period,      Func_DecrementPeriod
    d_entry table, Ch1Vibrato,     Func_DecrementVibrato
    d_entry table, NoiseVolume,    Func_DecrementVolume
    d_entry table, NoiseDecay,     Func_ToggleDecay
    d_entry table, NoisePeriod,    Func_DecrementPeriod
    D_END
.ENDREPEAT
.ENDPROC

;;; @param A The number of tile IDs to transfer.
;;; @return Y The index into Ram_PpuTransfer_start for the start of the data.
;;; @preserve X
.EXPORT Func_StartFieldValuePpuTransfer
.PROC Func_StartFieldValuePpuTransfer
    ldy Zp_PpuTransferLen_u8
    sta Ram_PpuTransfer_start, y
    iny
    add Zp_PpuTransferLen_u8
    adc #3
    sta Zp_PpuTransferLen_u8
    txa  ; old X value
    pha  ; old X value
    ldx Zp_Cursor_eField
    lda #0
    sta T0
    lda Data_FieldTileRow_u8_arr, x
    .assert SCREEN_WIDTH_TILES = 1 << 5, error
    .repeat 5
    asl a
    rol T0
    .endrepeat
    .assert <PPUADDR_NAME0 = 0, error
    add Data_FieldValueTileCol_u8_arr, x
    pha  ; dest addr (lo)
    lda T0
    adc #>PPUADDR_NAME0
    sta Ram_PpuTransfer_start, y
    iny
    pla  ; dest addr (lo)
    sta Ram_PpuTransfer_start, y
    iny
    pla  ; old X value
    tax  ; old X value
    rts
.ENDPROC

.EXPORT Func_DrawCursor
.PROC Func_DrawCursor
    lda #0
    sta Ram_Cursor_sObj + sObj::Flags_bObj
    lda #'>'
    sta Ram_Cursor_sObj + sObj::Tile_u8
    lda #$14
    sta Ram_Cursor_sObj + sObj::XPos_u8
    ldx Zp_Cursor_eField
    lda Data_FieldTileRow_u8_arr, x
    mul #kTileHeightPx
    sta Ram_Cursor_sObj + sObj::YPos_u8
    rts
.ENDPROC

;;;=========================================================================;;;
