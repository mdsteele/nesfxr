.INCLUDE "../apu.inc"
.INCLUDE "../macros.inc"

.IMPORT Func_SetChannelPeriod
.IMPORT Func_StartFieldValuePpuTransfer
.IMPORT Ram_PpuTransfer_start

;;;=========================================================================;;;

.BSS

.EXPORT Ram_ChannelBuzz_bool_arr
Ram_ChannelBuzz_bool_arr: .res eChannel::NUM_VALUES

;;;=========================================================================;;;

.CODE

;;; @param X The eChannel.
.EXPORT Func_ToggleBuzz
.PROC Func_ToggleBuzz
    lda Ram_ChannelBuzz_bool_arr, x
    eor #$ff
    sta Ram_ChannelBuzz_bool_arr, x
    jmp Func_UpdateBuzz
.ENDPROC

;;; @param X The eChannel.
.PROC Func_UpdateBuzz
    lda #3  ; param: transfer length
    jsr Func_StartFieldValuePpuTransfer  ; preserves X, returns Y
    lda Ram_ChannelBuzz_bool_arr, x
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
    jmp Func_SetChannelPeriod
_Yes:
    lda #'Y'
    sta Ram_PpuTransfer_start, y
    iny
    lda #'E'
    sta Ram_PpuTransfer_start, y
    iny
    lda #'S'
    sta Ram_PpuTransfer_start, y
    jmp Func_SetChannelPeriod
.ENDPROC

;;;=========================================================================;;;
