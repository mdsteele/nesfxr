.INCLUDE "../macros.inc"

.IMPORT Func_HexDigitToAscii
.IMPORT Func_SetCh1Sweep
.IMPORT Func_StartFieldValuePpuTransfer
.IMPORT Ram_PpuTransfer_start
.IMPORTZP Zp_Ch1SweepShift_i8

;;;=========================================================================;;;

kMaxSweepShift = 7
kMinSweepShift = <-7

;;;=========================================================================;;;

.CODE

.EXPORT Func_IncrementSweepShift
.PROC Func_IncrementSweepShift
    lda Zp_Ch1SweepShift_i8
    cmp #kMaxSweepShift
    bne @increment
    rts
    @increment:
    add #1
    sta Zp_Ch1SweepShift_i8
    jmp Func_UpdateSweepShift
.ENDPROC

.EXPORT Func_DecrementSweepShift
.PROC Func_DecrementSweepShift
    lda Zp_Ch1SweepShift_i8
    cmp #kMinSweepShift
    bne @decrement
    rts
    @decrement:
    sub #1
    sta Zp_Ch1SweepShift_i8
    jmp Func_UpdateSweepShift
.ENDPROC

.PROC Func_UpdateSweepShift
    lda #3  ; param: transfer length
    jsr Func_StartFieldValuePpuTransfer  ; returns Y
    lda Zp_Ch1SweepShift_i8
    beq _Off
    bmi _Neg
_Pos:
    lda #'+'
    sta Ram_PpuTransfer_start, y
    iny
    lda Zp_Ch1SweepShift_i8
    jsr Func_HexDigitToAscii  ; preserves Y
    sta Ram_PpuTransfer_start, y
    iny
    lda #' '
    sta Ram_PpuTransfer_start, y
    jmp Func_SetCh1Sweep
_Neg:
    lda #'-'
    sta Ram_PpuTransfer_start, y
    iny
    lda Zp_Ch1SweepShift_i8
    eor #$ff
    add #1
    jsr Func_HexDigitToAscii  ; preserves Y
    sta Ram_PpuTransfer_start, y
    iny
    lda #' '
    sta Ram_PpuTransfer_start, y
    jmp Func_SetCh1Sweep
_Off:
    lda #'O'
    sta Ram_PpuTransfer_start, y
    iny
    lda #'F'
    sta Ram_PpuTransfer_start, y
    iny
    lda #'F'
    sta Ram_PpuTransfer_start, y
    jmp Func_SetCh1Sweep
.ENDPROC

;;;=========================================================================;;;
