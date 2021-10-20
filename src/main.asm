.INCLUDE "oam.inc"
.INCLUDE "ppu.inc"

.IMPORT Func_ProcessFrame, Ram_Cursor_oama, Ram_PpuTransfer_start
.IMPORTZP Zp_PpuMask_u8

;;;=========================================================================;;;

.CODE

.EXPORT Main
.PROC Main
    lda #PPUMASK_ALL
    sta Zp_PpuMask_u8
_SetUpPpuTransfer:
    lda #4  ; length
    sta Ram_PpuTransfer_start + 0
    lda #>PPUADDR_PALETTES
    sta Ram_PpuTransfer_start + 1
    lda #<PPUADDR_PALETTES
    sta Ram_PpuTransfer_start + 2
    lda #$08  ; very dark yellow
    sta Ram_PpuTransfer_start + 3
    lda #$19  ; dark green
    sta Ram_PpuTransfer_start + 4
    lda #$2a  ; green
    sta Ram_PpuTransfer_start + 5
    lda #$3a  ; light green
    sta Ram_PpuTransfer_start + 6
    lda #3  ; length
    sta Ram_PpuTransfer_start + 7
    lda #>(PPUADDR_PALETTES + $11)
    sta Ram_PpuTransfer_start + 8
    lda #<(PPUADDR_PALETTES + $11)
    sta Ram_PpuTransfer_start + 9
    lda #$16  ; red
    sta Ram_PpuTransfer_start + 10
    lda #$16  ; red
    sta Ram_PpuTransfer_start + 11
    lda #$16  ; red
    sta Ram_PpuTransfer_start + 12
    lda #0
    sta Ram_PpuTransfer_start + 13
_InitOam:
    lda #OAMF_YFLIP
    sta Ram_Cursor_oama + OAMA::Flags
    lda #'&'
    sta Ram_Cursor_oama + OAMA::Tile
    lda #4
    sta Ram_Cursor_oama + OAMA::XPos
    lda #0
    sta Ram_Cursor_oama + OAMA::YPos
_GameLoop:
    inc Ram_Cursor_oama + OAMA::YPos
    lda Ram_Cursor_oama + OAMA::YPos
    cmp #$40
    bne :+
    lda #1  ; length
    sta Ram_PpuTransfer_start + 0
    lda #>PPUADDR_PALETTES
    sta Ram_PpuTransfer_start + 1
    lda #<PPUADDR_PALETTES
    sta Ram_PpuTransfer_start + 2
    lda #$09  ; very dark green
    sta Ram_PpuTransfer_start + 3
    lda #0
    sta Ram_PpuTransfer_start + 4
    :
    lda Ram_Cursor_oama + OAMA::YPos
    cmp #$c0
    bne :+
    lda #1  ; length
    sta Ram_PpuTransfer_start + 0
    lda #>PPUADDR_PALETTES
    sta Ram_PpuTransfer_start + 1
    lda #<PPUADDR_PALETTES
    sta Ram_PpuTransfer_start + 2
    lda #$08  ; very dark yellow
    sta Ram_PpuTransfer_start + 3
    lda #0
    sta Ram_PpuTransfer_start + 4
    :
    jsr Func_ProcessFrame
    jmp _GameLoop
.ENDPROC

;;;=========================================================================;;;
