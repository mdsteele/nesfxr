.INCLUDE "../field.inc"
.INCLUDE "../macros.inc"

.IMPORT Func_HexDigitToAscii
.IMPORT Func_StartFieldValuePpuTransfer
.IMPORT Ram_PpuTransfer_start
.IMPORTZP Zp_Ch1VibratoDepth_u8

;;;=========================================================================;;;

.CODE

.EXPORT Func_IncrementVibrato
.PROC Func_IncrementVibrato
    lda Zp_Ch1VibratoDepth_u8
    bne @nonzero
    inc Zp_Ch1VibratoDepth_u8
    jmp Func_UpdateVibrato
    @nonzero:
    bpl @shift
    rts
    @shift:
    asl Zp_Ch1VibratoDepth_u8
    jmp Func_UpdateVibrato
.ENDPROC

.EXPORT Func_DecrementVibrato
.PROC Func_DecrementVibrato
    lsr Zp_Ch1VibratoDepth_u8
    jmp Func_UpdateVibrato
.ENDPROC

.PROC Func_UpdateVibrato
    ldy #eField::Ch1Vibrato  ; param: eField
    lda #2  ; param: transfer length
    jsr Func_StartFieldValuePpuTransfer  ; returns X
    ;; Buffer first digit:
    lda Zp_Ch1VibratoDepth_u8
    div #$10
    jsr Func_HexDigitToAscii  ; preserves X
    sta Ram_PpuTransfer_start, x
    inx
    ;; Buffer second digit:
    lda Zp_Ch1VibratoDepth_u8
    and #$0f
    jsr Func_HexDigitToAscii  ; preserves X
    sta Ram_PpuTransfer_start, x
    rts
.ENDPROC

;;;=========================================================================;;;
