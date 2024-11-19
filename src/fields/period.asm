.INCLUDE "../apu.inc"
.INCLUDE "../joypad.inc"
.INCLUDE "../macros.inc"

.IMPORT Func_HexDigitToAscii
.IMPORT Func_SetChannelPeriod
.IMPORT Func_StartFieldValuePpuTransfer
.IMPORT Ram_PpuTransfer_start
.IMPORTZP Zp_P1ButtonsHeld_u8

;;;=========================================================================;;;

kMaxWavePeriod = $7ff
kMaxNoisePeriod = $f

;;;=========================================================================;;;

.BSS

.EXPORT Ram_ChannelPeriod_u16_0_arr
Ram_ChannelPeriod_u16_0_arr: .res eChannel::NUM_VALUES
.EXPORT Ram_ChannelPeriod_u16_1_arr
Ram_ChannelPeriod_u16_1_arr: .res eChannel::NUM_VALUES

;;;=========================================================================;;;

.CODE

;;; @param X The eChannel.
.EXPORT Func_IncrementPeriod
.PROC Func_IncrementPeriod
    cpx #eChannel::Noise
    bne _Wave
_Noise:
    lda Ram_ChannelPeriod_u16_0_arr, x
    cmp #kMaxNoisePeriod
    blt @increment
    rts
    @increment:
    add #1
    sta Ram_ChannelPeriod_u16_0_arr, x
    jmp Func_UpdatePeriod
_Wave:
    jsr Func_GetPeriodDelta  ; preserves X, returns T1T0
    lda Ram_ChannelPeriod_u16_0_arr, x
    add T0
    sta Ram_ChannelPeriod_u16_0_arr, x
    lda Ram_ChannelPeriod_u16_1_arr, x
    adc T1
    sta Ram_ChannelPeriod_u16_1_arr, x
    ;; Clamp channel period to kMaxWavePeriod.
    lda Ram_ChannelPeriod_u16_1_arr, x
    cmp #>(kMaxWavePeriod + 1)
    blt @noClamp
    bne @clamp
    lda Ram_ChannelPeriod_u16_0_arr, x
    cmp #<(kMaxWavePeriod + 1)
    blt @noClamp
    @clamp:
    lda #>kMaxWavePeriod
    sta Ram_ChannelPeriod_u16_1_arr, x
    lda #<kMaxWavePeriod
    sta Ram_ChannelPeriod_u16_0_arr, x
    @noClamp:
    jmp Func_UpdatePeriod
.ENDPROC

;;; @param X The eChannel.
.EXPORT Func_DecrementPeriod
.PROC Func_DecrementPeriod
    cpx #eChannel::Noise
    bne _Wave
_Noise:
    lda Ram_ChannelPeriod_u16_0_arr, x
    bne @decrement
    rts
    @decrement:
    sub #1
    sta Ram_ChannelPeriod_u16_0_arr, x
    jmp Func_UpdatePeriod
_Wave:
    jsr Func_GetPeriodDelta  ; preserves X, returns T1T0
    ;; If T1T0 > period, set period to zero.
    lda Ram_ChannelPeriod_u16_0_arr, x
    cmp T0
    lda Ram_ChannelPeriod_u16_1_arr, x
    sbc T1
    bge @noClamp
    lda #0
    sta Ram_ChannelPeriod_u16_0_arr, x
    sta Ram_ChannelPeriod_u16_1_arr, x
    jmp Func_UpdatePeriod
    @noClamp:
    ;; Subtract T1T0 from channel period.
    lda Ram_ChannelPeriod_u16_0_arr, x
    sub T0
    sta Ram_ChannelPeriod_u16_0_arr, x
    lda Ram_ChannelPeriod_u16_1_arr, x
    sbc T1
    sta Ram_ChannelPeriod_u16_1_arr, x
    jmp Func_UpdatePeriod
.ENDPROC

;;; @param X The eChannel.
.PROC Func_UpdatePeriod
_StartTransfer:
    cpx #eChannel::Noise
    beq @noise
    lda #3  ; param: transfer length
    bne @start
    @noise:
    lda #1  ; param: transfer length
    @start:
    jsr Func_StartFieldValuePpuTransfer  ; preserves X, returns Y
_BufferDigits:
    cpx #eChannel::Noise
    beq @lastDigit
    lda Ram_ChannelPeriod_u16_1_arr, x
    jsr Func_HexDigitToAscii  ; preserves X and Y
    sta Ram_PpuTransfer_start, y
    iny
    lda Ram_ChannelPeriod_u16_0_arr, x
    div #$10
    jsr Func_HexDigitToAscii  ; preserves X and Y
    sta Ram_PpuTransfer_start, y
    iny
    @lastDigit:
    lda Ram_ChannelPeriod_u16_0_arr, x
    and #$0f
    jsr Func_HexDigitToAscii  ; preserves X and Y
    sta Ram_PpuTransfer_start, y
    ;; Update audio registers:
    jmp Func_SetChannelPeriod
.ENDPROC

;;; @return T1T0
;;; @preserve X
.PROC Func_GetPeriodDelta
    lda Zp_P1ButtonsHeld_u8
    and #bJoypad::AButton
    beq @not100
    lda #$01
    sta T1
    lda #$00
    sta T0
    rts
    @not100:
    lda Zp_P1ButtonsHeld_u8
    and #bJoypad::BButton
    beq @not10
    lda #$00
    sta T1
    lda #$10
    sta T0
    rts
    @not10:
    lda #$00
    sta T1
    lda #$01
    sta T0
    rts
.ENDPROC

;;;=========================================================================;;;
