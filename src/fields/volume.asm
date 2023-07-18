.INCLUDE "../field.inc"
.INCLUDE "../macros.inc"

.IMPORT Func_HexDigitToAscii
.IMPORT Func_SetCh1Env
.IMPORT Func_StartFieldValuePpuTransfer
.IMPORT Ram_PpuTransfer_start
.IMPORTZP Zp_Ch1Volume_u8

;;;=========================================================================;;;

kMaxVolume = $f

;;;=========================================================================;;;

.CODE

.EXPORT Func_IncrementVolume
.PROC Func_IncrementVolume
    lda Zp_Ch1Volume_u8
    cmp #kMaxVolume
    blt @increment
    rts
    @increment:
    add #1
    sta Zp_Ch1Volume_u8
    jmp Func_UpdateVolume
.ENDPROC

.EXPORT Func_DecrementVolume
.PROC Func_DecrementVolume
    lda Zp_Ch1Volume_u8
    bne @decrement
    rts
    @decrement:
    sub #1
    sta Zp_Ch1Volume_u8
    jmp Func_UpdateVolume
.ENDPROC

.PROC Func_UpdateVolume
    ldy #eField::Ch1Volume  ; param: eField
    lda #1  ; param: transfer length
    jsr Func_StartFieldValuePpuTransfer  ; returns X
    ;; Buffer first (only) digit:
    lda Zp_Ch1Volume_u8
    jsr Func_HexDigitToAscii  ; preserves X
    sta Ram_PpuTransfer_start, x
    ;; Update audio register:
    jmp Func_SetCh1Env
.ENDPROC

;;;=========================================================================;;;
