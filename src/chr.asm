;;;=========================================================================;;;

.DEFINE kSizeofChr 16

;;;=========================================================================;;;

.SEGMENT "CHR"

.PROC Ppu_ChrBg
:   .res kSizeofChr * $21
    .incbin "out/data/font.chr"
    .res kSizeofChr * $81
    .assert * - :- = kSizeofChr * $100, error
.ENDPROC

.PROC PpuChrObj
:   .res kSizeofChr * $21
    .incbin "out/data/font.chr"
    .res kSizeofChr * $81
    .assert * - :- = kSizeofChr * $100, error
.ENDPROC

;;;=========================================================================;;;
