.INCLUDE "oam.inc"

;;;=========================================================================;;;

.SEGMENT "OAM"

.EXPORT Ram_ShadowOam_oama_arr64
Ram_ShadowOam_oama_arr64:

.EXPORT Ram_Cursor_oama
Ram_Cursor_oama: .tag OAMA

;;;=========================================================================;;;

.CODE

;; Places all sprites offscreen.
.EXPORT Func_OamClear
.PROC Func_OamClear
    lda #$fe
    ldx #0
    @loop:
    .assert OAMA::YPos = 0, error
    sta Ram_ShadowOam_oama_arr64, X
    .assert .sizeof(OAMA) = 4, error
    inx
    inx
    inx
    inx
    bne @loop
    rts
.ENDPROC

;;;=========================================================================;;;
