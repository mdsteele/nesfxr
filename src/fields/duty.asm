.INCLUDE "../apu.inc"
.INCLUDE "../field.inc"
.INCLUDE "../macros.inc"

.IMPORT Func_SetCh1Env
.IMPORT Func_StartFieldValuePpuTransfer
.IMPORT Ram_PpuTransfer_start
.IMPORTZP Zp_Ch1Duty_eDuty

;;;=========================================================================;;;

.CODE

.EXPORT Func_IncrementDuty
.PROC Func_IncrementDuty
    ldx Zp_Ch1Duty_eDuty
    inx
    cpx #eDuty::NUM_VALUES
    blt @setDuty
    rts
    @setDuty:
    stx Zp_Ch1Duty_eDuty
    jmp Func_UpdateDuty
.ENDPROC

.EXPORT Func_DecrementDuty
.PROC Func_DecrementDuty
    lda Zp_Ch1Duty_eDuty
    bne @decrement
    rts
    @decrement:
    dec Zp_Ch1Duty_eDuty
    jmp Func_UpdateDuty
.ENDPROC

.PROC Func_UpdateDuty
    ldy #eField::Ch1Duty  ; param: eField
    lda #3  ; param: transfer length
    jsr Func_StartFieldValuePpuTransfer  ; returns X
    ;; Buffer first digit:
    ldy Zp_Ch1Duty_eDuty
    lda _DutyNumerator_u8_arr, y
    sta Ram_PpuTransfer_start, x
    inx
    ;; Buffer slash:
    lda #'/'
    sta Ram_PpuTransfer_start, x
    inx
    ;; Buffer second digit:
    lda _DutyDenominator_u8_arr, y
    sta Ram_PpuTransfer_start, x
    ;; Update audio register:
    jmp Func_SetCh1Env
_DutyNumerator_u8_arr:
    D_ENUM eDuty
    d_byte _1_8, '1'
    d_byte _1_4, '1'
    d_byte _1_2, '1'
    d_byte _3_4, '3'
    D_END
_DutyDenominator_u8_arr:
    D_ENUM eDuty
    d_byte _1_8, '8'
    d_byte _1_4, '4'
    d_byte _1_2, '2'
    d_byte _3_4, '4'
    D_END
.ENDPROC

;;;=========================================================================;;;
