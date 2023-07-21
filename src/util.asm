.INCLUDE "macros.inc"

;;;=========================================================================;;;

.EXPORT Func_Noop
.PROC Func_Noop
    rts
.ENDPROC

;;; @param A The hex digit, from 0-F.
;;; @return A The ASCII value.
;;; @preserve X, Y, T0+
.EXPORT Func_HexDigitToAscii
.PROC Func_HexDigitToAscii
    cmp #$a
    bge @letter
    add #'0'
    rts
    @letter:
    add #('A' - 10)
    rts
.ENDPROC

;;;=========================================================================;;;
