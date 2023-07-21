.INCLUDE "../macros.inc"

.IMPORT Func_HexDigitToAscii
.IMPORT Func_SetCh1Sweep
.IMPORT Func_StartFieldValuePpuTransfer
.IMPORT Ram_PpuTransfer_start
.IMPORTZP Zp_Ch1SweepPeriod_u8

;;;=========================================================================;;;

kMaxSweepPeriod = 7

;;;=========================================================================;;;

.CODE

.EXPORT Func_IncrementSweepPeriod
.PROC Func_IncrementSweepPeriod
    lda Zp_Ch1SweepPeriod_u8
    cmp #kMaxSweepPeriod
    blt @increment
    rts
    @increment:
    add #1
    sta Zp_Ch1SweepPeriod_u8
    jmp Func_UpdateSweepPeriod
.ENDPROC

.EXPORT Func_DecrementSweepPeriod
.PROC Func_DecrementSweepPeriod
    lda Zp_Ch1SweepPeriod_u8
    bne @decrement
    rts
    @decrement:
    sub #1
    sta Zp_Ch1SweepPeriod_u8
    jmp Func_UpdateSweepPeriod
.ENDPROC

.PROC Func_UpdateSweepPeriod
    lda #1  ; param: transfer length
    jsr Func_StartFieldValuePpuTransfer  ; returns Y
    ;; Buffer first (only) digit:
    lda Zp_Ch1SweepPeriod_u8
    jsr Func_HexDigitToAscii  ; preserves Y
    sta Ram_PpuTransfer_start, y
    ;; Update audio register:
    jmp Func_SetCh1Sweep
.ENDPROC

;;;=========================================================================;;;
