.INCLUDE "field.inc"
.INCLUDE "macros.inc"
.INCLUDE "ppu.inc"

.IMPORT Ram_PpuTransfer_start
.IMPORTZP Zp_PpuTransferLen_u8

;;;=========================================================================;;;

.RODATA

.EXPORT Data_FieldTileRow_u8
.PROC Data_FieldTileRow_u8
    D_ENUM eField
    d_byte Ch1Duty,    2
    d_byte Ch1Volume,  3
    d_byte Ch1Period,  4
    d_byte Ch1Vibrato, 5
    D_END
.ENDPROC

.PROC Data_FieldValueTileCol_u8
    D_ENUM eField
    d_byte Ch1Duty,    13
    d_byte Ch1Volume,  14
    d_byte Ch1Period,  14
    d_byte Ch1Vibrato, 14
    D_END
.ENDPROC

;;;=========================================================================;;;

.CODE

;;; @param Y The eField.
;;; @param A The number of tile IDs to transfer.
;;; @return X The index into Ram_PpuTransfer_start for the start of the data.
.EXPORT Func_StartFieldValuePpuTransfer
.PROC Func_StartFieldValuePpuTransfer
    ldx Zp_PpuTransferLen_u8
    sta Ram_PpuTransfer_start, x
    inx
    add Zp_PpuTransferLen_u8
    adc #3
    sta Zp_PpuTransferLen_u8
    lda #0
    sta T0
    lda Data_FieldTileRow_u8, y
    .assert SCREEN_WIDTH_TILES = 1 << 5, error
    .repeat 5
    asl a
    rol T0
    .endrepeat
    .assert <PPUADDR_NAME0 = 0, error
    add Data_FieldValueTileCol_u8, y
    pha
    lda T0
    adc #>PPUADDR_NAME0
    sta Ram_PpuTransfer_start, x
    inx
    pla
    sta Ram_PpuTransfer_start, x
    inx
    rts
.ENDPROC

;;;=========================================================================;;;
