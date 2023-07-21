.INCLUDE "../apu.inc"
.INCLUDE "../macros.inc"

.IMPORT Func_HexDigitToAscii
.IMPORT Func_SetChannelEnv
.IMPORT Func_StartFieldValuePpuTransfer
.IMPORT Ram_PpuTransfer_start

;;;=========================================================================;;;

kMaxVolume = $f

;;;=========================================================================;;;

.BSS

.EXPORT Ram_ChannelVolume_u8_arr
Ram_ChannelVolume_u8_arr: .res eChannel::NUM_VALUES

;;;=========================================================================;;;

.CODE

;;; @param X The eChannel.
.EXPORT Func_IncrementVolume
.PROC Func_IncrementVolume
    lda Ram_ChannelVolume_u8_arr, x
    cmp #kMaxVolume
    blt @increment
    rts
    @increment:
    add #1
    sta Ram_ChannelVolume_u8_arr, x
    jmp Func_UpdateVolume
.ENDPROC

;;; @param X The eChannel.
.EXPORT Func_DecrementVolume
.PROC Func_DecrementVolume
    lda Ram_ChannelVolume_u8_arr, x
    bne @decrement
    rts
    @decrement:
    sub #1
    sta Ram_ChannelVolume_u8_arr, x
    jmp Func_UpdateVolume
.ENDPROC

;;; @param X The eChannel.
.PROC Func_UpdateVolume
    lda #1  ; param: transfer length
    jsr Func_StartFieldValuePpuTransfer  ; preserves X, returns Y
    lda Ram_ChannelVolume_u8_arr, x  ; param: hex digit
    jsr Func_HexDigitToAscii  ; preserves X and Y
    sta Ram_PpuTransfer_start, y
    jmp Func_SetChannelEnv
.ENDPROC

;;;=========================================================================;;;
