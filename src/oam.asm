.INCLUDE "oam.inc"

;;;=========================================================================;;;

.SEGMENT "OAM"

.EXPORT Ram_ShadowOam_sObj_arr64
Ram_ShadowOam_sObj_arr64:

.EXPORT Ram_Cursor_sObj
Ram_Cursor_sObj: .tag sObj

;;;=========================================================================;;;

.CODE

;;; Places all sprites offscreen.
.EXPORT Func_OamClear
.PROC Func_OamClear
    lda #$fe
    ldx #0
    @loop:
    .assert sObj::YPos_u8 = 0, error
    sta Ram_ShadowOam_sObj_arr64, X
    .repeat .sizeof(sObj)
    inx
    .endrepeat
    bne @loop
    rts
.ENDPROC

;;;=========================================================================;;;
