.MACPACK generic
.MACPACK longbranch

;;;=========================================================================;;;

.DEFINE _is_immediate(arg) .match(.left(1, {arg}), #)
.DEFINE _get_immediate(arg) .right(.tcount({arg}) - 1, {arg})

.MACRO _lo_byte op, arg
    .if _is_immediate arg
    op #<_get_immediate arg
    .else
    op arg
    .endif
.ENDMACRO

.MACRO _hi_byte op, arg
    .if _is_immediate arg
    op #>_get_immediate arg
    .else
    op (arg) + 1
    .endif
.ENDMACRO

;;;=========================================================================;;;

;;; Loads a 16-bit value, putting the high byte in A and the low byte in X.
;;;
;;; Examples:
;;;     ldax #$1234       ; immidiate mode; sets X to $34 and A to $12
;;;     ldax Zp_Foo_u16   ; zeropage mode; sets [Foo] to X and [Foo+1] to A
;;;     ldax Ram_Foo_u16  ; absolute mode; sets [Foo] to X and [Foo+1] to A
.MACRO ldax arg
    _lo_byte ldx, arg
    _hi_byte lda, arg
.ENDMACRO

;;; Stores a 16-bit value, taking high byte from A and the low byte from X.
;;;
;;; Examples:
;;;     stax Zp_Foo_u16   ; zeropage mode; sets [Foo] to X and [Foo+1] to A
;;;     stax Ram_Foo_u16  ; absolute mode; sets [Foo] to X and [Foo+1] to A
.MACRO stax arg
    _lo_byte stx, arg
    _hi_byte sta, arg
.ENDMACRO

;;;=========================================================================;;;
