;;; The iNES header.  See https://wiki.nesdev.org/w/index.php/INES.  This is
;;; used for constructing the iNES-format ROM container file, and is used by
;;; emulators, but does not appear on a real NES cartridge.

;;;=========================================================================;;;

INES_MAPPER = 0  ; 0 = NROM
INES_MIRROR = 1  ; 0 = horizontal mirroring, 1 = vertical mirroring
INES_SRAM   = 0  ; 1 = battery backed SRAM at $6000-7FFF

;;;=========================================================================;;;

.SEGMENT "HEADER"
    .byte 'N', 'E', 'S', $1A  ; Magic number
    .byte $02  ; 16k PRG chunk count
    .byte $01  ; 8k CHR chunk count
    .byte INES_MIRROR | (INES_SRAM << 1) | ((INES_MAPPER & $f) << 4)
    .byte (INES_MAPPER & %11110000)
    .byte $0, $0, $0, $0, $0, $0, $0, $0  ; padding

;;;=========================================================================;;;
