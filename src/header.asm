;;; The iNES header.  See https://wiki.nesdev.org/w/index.php/INES.  This is
;;; used for constructing the iNES-format ROM container file, and is used by
;;; emulators, but does not appear on a real NES cartridge.

;;;=========================================================================;;;

kMapper     = 0  ; 0 = NROM
kPrgRomSize = 2  ; number of 16k PRG ROM chunks (should be a power of 2)
kChrRomSize = 1  ; number of 8k CHR ROM chunks (should be a power of 2)
kMirror     = 1  ; 0 = horizontal mirroring, 1 = vertical mirroring
kHasSram    = 0  ; 1 = battery backed SRAM at $6000-7FFF

;;;=========================================================================;;;

.SEGMENT "HEADER"
    .byte "NES", $1a  ; magic number
    .byte kPrgRomSize
    .byte kChrRomSize
    .byte kMirror | (kHasSram << 1) | ((kMapper & $f) << 4)
    .byte (kMapper & %11110000)
    .byte $0, $0, $0, $0, $0, $0, $0, $0  ; padding

;;;=========================================================================;;;
