.INCLUDE "../joypad.inc"
.INCLUDE "../macros.inc"

.IMPORT Func_HexDigitToAscii
.IMPORT Func_SetCh1Period
.IMPORT Func_StartFieldValuePpuTransfer
.IMPORT Ram_PpuTransfer_start
.IMPORTZP Zp_Ch1Period_u16
.IMPORTZP Zp_P1ButtonsHeld_u8

;;;=========================================================================;;;

kMaxPeriod = $3ff

;;;=========================================================================;;;

.EXPORT Func_IncrementPeriod
.PROC Func_IncrementPeriod
    ;; Store increment amount in XY.
    lda Zp_P1ButtonsHeld_u8
    and #bJoypad::AButton
    beq @not100
    ldx #$01
    ldy #$00
    beq @increment  ; unconditional
    @not100:
    lda Zp_P1ButtonsHeld_u8
    and #bJoypad::BButton
    beq @not10
    ldx #$00
    ldy #$10
    bne @increment  ; unconditional
    @not10:
    ldx #$00
    ldy #$01
    ;; Add XY to Zp_Ch1Period_u16.
    @increment:
    tya
    add Zp_Ch1Period_u16 + 0
    sta Zp_Ch1Period_u16 + 0
    txa
    adc Zp_Ch1Period_u16 + 1
    sta Zp_Ch1Period_u16 + 1
    ;; Clamp Zp_Ch1Period_u16 to kMaxPeriod.
    lda Zp_Ch1Period_u16 + 1
    cmp #>(kMaxPeriod + 1)
    blt @noClamp
    lda Zp_Ch1Period_u16 + 0
    cmp #<(kMaxPeriod + 1)
    blt @noClamp
    lda #>kMaxPeriod
    sta Zp_Ch1Period_u16 + 1
    lda #<kMaxPeriod
    sta Zp_Ch1Period_u16 + 0
    @noClamp:
    jmp Func_UpdatePeriod
.ENDPROC

.EXPORT Func_DecrementPeriod
.PROC Func_DecrementPeriod
    ;; Store decrement amount in XY.
    lda Zp_P1ButtonsHeld_u8
    and #bJoypad::AButton
    beq @not100
    ldx #$01
    ldy #$00
    beq @compare  ; unconditional
    @not100:
    lda Zp_P1ButtonsHeld_u8
    and #bJoypad::BButton
    beq @not10
    ldx #$00
    ldy #$10
    bne @compare  ; unconditional
    @not10:
    ldx #$00
    ldy #$01
    ;; If XY >= Zp_Ch1Period_u16, set Zp_Ch1Period_u16 to zero.
    @compare:
    txa
    cmp Zp_Ch1Period_u16 + 1
    blt @noClamp
    tya
    cmp Zp_Ch1Period_u16 + 0
    blt @noClamp
    lda #0
    sta Zp_Ch1Period_u16 + 0
    sta Zp_Ch1Period_u16 + 1
    jmp Func_UpdatePeriod
    @noClamp:
    ;; Subtract XY from Zp_Ch1Period_u16.
    tya
    eor #$ff
    sec
    adc Zp_Ch1Period_u16 + 0
    sta Zp_Ch1Period_u16 + 0
    txa
    eor #$ff
    adc Zp_Ch1Period_u16 + 1
    sta Zp_Ch1Period_u16 + 1
    jmp Func_UpdatePeriod
.ENDPROC

.PROC Func_UpdatePeriod
    lda #3  ; param: transfer length
    jsr Func_StartFieldValuePpuTransfer  ; returns Y
    ;; Buffer first digit:
    lda Zp_Ch1Period_u16 + 1
    jsr Func_HexDigitToAscii  ; preserves Y
    sta Ram_PpuTransfer_start, y
    iny
    ;; Buffer second digit:
    lda Zp_Ch1Period_u16 + 0
    div #$10
    jsr Func_HexDigitToAscii  ; preserves Y
    sta Ram_PpuTransfer_start, y
    iny
    ;; Buffer third digit:
    lda Zp_Ch1Period_u16 + 0
    and #$0f
    jsr Func_HexDigitToAscii  ; preserves Y
    sta Ram_PpuTransfer_start, y
    ;; Update audio registers:
    jmp Func_SetCh1Period
.ENDPROC

;;;=========================================================================;;;
