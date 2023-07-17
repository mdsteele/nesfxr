;;; See https://wiki.nesdev.org/w/index.php/PPU_OAM and
;;; https://wiki.nesdev.org/w/index.php/PPU_registers

;;;=========================================================================;;;

;;; Writing here sets the start OAM address used by Hw_OamDma_wo.
Hw_OamAddr_wo = $2003

;;; Writing $xx here will upload CPU page $xx00-$xxff to the internal PPU OAM.
;;; The CPU is suspended during the transfer.
Hw_OamDma_wo  = $4014

;;;=========================================================================;;;

.STRUCT sObj
    YPos_u8    .byte
    Tile_u8    .byte
    Flags_bObj .byte
    XPos_u8    .byte
.ENDSTRUCT

;;;=========================================================================;;;

.SCOPE bObj
    FlipV       = %10000000  ; flip object vertically
    FlipH       = %01000000  ; flip object horizontally
    FlipHV      = %11000000  ; flip object both horizontally and vertically
    Pri         = %00100000  ; draw object behind background
    PaletteMask = %00000011  ; bits used for the OBJ palette number
.ENDSCOPE

;;;=========================================================================;;;
