.INCLUDE "../apu.inc"
.INCLUDE "../macros.inc"

.IMPORT Func_SetChannelEnv
.IMPORT Func_StartFieldValuePpuTransfer
.IMPORT Ram_PpuTransfer_start

;;;=========================================================================;;;

.BSS

.EXPORT Ram_ChannelDecay_bool_arr
Ram_ChannelDecay_bool_arr: .res eChannel::NUM_VALUES

;;;=========================================================================;;;

.CODE

;;; @param X The eChannel.
.EXPORT Func_ToggleDecay
.PROC Func_ToggleDecay
    lda Ram_ChannelDecay_bool_arr, x
    eor #$ff
    sta Ram_ChannelDecay_bool_arr, x
    jmp Func_UpdateDecay
.ENDPROC

;;; @param X The eChannel.
.PROC Func_UpdateDecay
    lda #3  ; param: transfer length
    jsr Func_StartFieldValuePpuTransfer  ; preserves X, returns Y
    lda Ram_ChannelDecay_bool_arr, x
    bmi _Yes
_No:
    lda #'N'
    sta Ram_PpuTransfer_start, y
    iny
    lda #'O'
    sta Ram_PpuTransfer_start, y
    iny
    lda #' '
    sta Ram_PpuTransfer_start, y
    jmp Func_SetChannelEnv
_Yes:
    lda #'Y'
    sta Ram_PpuTransfer_start, y
    iny
    lda #'E'
    sta Ram_PpuTransfer_start, y
    iny
    lda #'S'
    sta Ram_PpuTransfer_start, y
    jmp Func_SetChannelEnv
.ENDPROC

;;;=========================================================================;;;
