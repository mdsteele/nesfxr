;;; See https://wiki.nesdev.org/w/index.php/PPU_OAM and
;;; https://wiki.nesdev.org/w/index.php/PPU_registers

;;;=========================================================================;;;

rOAMADDR = $2003
rOAMDATA = $2004
rOAMDMA  = $4014

;;;=========================================================================;;;

.STRUCT OAMA
    YPos  .byte
    Tile  .byte
    Flags .byte
    XPos  .byte
.ENDSTRUCT

;;;=========================================================================;;;

OAMF_YFLIP = %10000000
OAMF_XFLIP = %01000000
OAMF_PRI   = %00100000

;;;=========================================================================;;;
