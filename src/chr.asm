;;;=========================================================================;;;

SIZEOF_CHR = 16

;;;=========================================================================;;;

.SEGMENT "CHR"
    ;; Pattern table 0:
    .assert * = $0000, error
    .res SIZEOF_CHR * $21
    .incbin "out/data/font.chr"
    .res SIZEOF_CHR * $81
    ;; Pattern table 1:
    .assert * = $1000, error
    .res SIZEOF_CHR * $21
    .incbin "out/data/font.chr"
    .res SIZEOF_CHR * $81
    .assert * = $2000, error

;;;=========================================================================;;;
