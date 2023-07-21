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
    lda #2  ; param: transfer length
    jsr Func_StartFieldValuePpuTransfer  ; returns Y
    ;; Buffer first digit:
    lda Zp_Ch1VibratoDepth_u8
    div #$10
    jsr Func_HexDigitToAscii  ; preserves Y
    sta Ram_PpuTransfer_start, y
    iny
    ;; Buffer second digit:
    lda Zp_Ch1VibratoDepth_u8
    and #$0f
    jsr Func_HexDigitToAscii  ; preserves Y
    sta Ram_PpuTransfer_start, y
    rts
.ENDPROC

;;;=========================================================================;;;
