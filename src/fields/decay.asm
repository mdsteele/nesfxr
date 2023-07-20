.INCLUDE "../field.inc"
.INCLUDE "../macros.inc"

.IMPORT Func_SetCh1Env
.IMPORT Func_StartFieldValuePpuTransfer
.IMPORT Ram_PpuTransfer_start
.IMPORTZP Zp_Ch1Decay_bool

;;;=========================================================================;;;

.CODE

.EXPORT Func_ToggleDecay
.PROC Func_ToggleDecay
    lda Zp_Ch1Decay_bool
    eor #$ff
    sta Zp_Ch1Decay_bool
    jmp Func_UpdateDecay
.ENDPROC

.PROC Func_UpdateDecay
    ldy #eField::Ch1Decay  ; param: eField
    lda #3  ; param: transfer length
    jsr Func_StartFieldValuePpuTransfer  ; returns X
    bit Zp_Ch1Decay_bool
    bmi _Yes
_No:
    lda #'N'
    sta Ram_PpuTransfer_start, x
    inx
    lda #'O'
    sta Ram_PpuTransfer_start, x
    inx
    lda #' '
    sta Ram_PpuTransfer_start, x
    jmp Func_SetCh1Env
_Yes:
    lda #'Y'
    sta Ram_PpuTransfer_start, x
    inx
    lda #'E'
    sta Ram_PpuTransfer_start, x
    inx
    lda #'S'
    sta Ram_PpuTransfer_start, x
    jmp Func_SetCh1Env
.ENDPROC

;;;=========================================================================;;;
