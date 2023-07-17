;;; See https://wiki.nesdev.org/w/index.php/PPU_registers

;;;=========================================================================;;;

;;; PPU control register.
;;;
;;; When using the MMC3 mapper's IRQ feature, it is best to use 8x8 objects,
;;; and use pattern table $0000 for BG and $1000 for objects.  For details, see
;;; https://wiki.nesdev.org/w/index.php/MMC3#IRQ_Specifics and
;;; https://wiki.nesdev.org/w/index.php/Sprite_size.
Hw_PpuCtrl_wo = $2000

.SCOPE bPpuCtrl
    EnableNmi = %10000000  ; enable NMI interrupts for VBlank
    Obj8x16   = %00100000  ; use 8x16 objects (instead of 8x8)
    BgPat1    = %00010000  ; use pattern table 1 ($1000) for background
    ObjPat1   = %00001000  ; use pattern table 1 ($1000) for objects
    Inc32     = %00000100  ; increment VRAM addr by 32 per PpuData read/write
    NameMask  = %00000011  ; bits used to specify base nametable for scrolling
.ENDSCOPE

;;;=========================================================================;;;

;;; PPU rendering mask.  Set this to zero to disable rendering, which will
;;; allow access to the PPU outside of VBlank.
Hw_PpuMask_wo = $2001

.SCOPE bPpuMask
    EmphBlue  = %10000000  ; emphasize blue
    EmphGreen = %01000000  ; emphasize green
    EmphRed   = %00100000  ; emphasize red
    ObjMain   = %00010000  ; draw objects in main part of screen
    BgMain    = %00001000  ; draw background in main part of screen
    ObjLeft   = %00000100  ; draw objects in leftmost part of screen
    BgLeft    = %00000010  ; draw background in leftmost part of screen
    Grayscale = %00000001  ; grayscale mode
    ObjAll    = %00010100  ; draw objects everywhere
    BgAll     = %00001010  ; draw objects everywhere
.ENDSCOPE

.ASSERT bPpuMask::ObjAll = bPpuMask::ObjMain | bPpuMask::ObjLeft, error
.ASSERT bPpuMask::BgAll = bPpuMask::BgMain | bPpuMask::BgLeft, error

;;;=========================================================================;;;

;;; PPU status register.  Reading this will clear bit 7 (bPpuStatus::VBlank),
;;; and will also reset the write-twice latch for Hw_PpuScroll_w2 and
;;; Hw_PpuAddr_w2.
Hw_PpuStatus_ro = $2002

.SCOPE bPpuStatus
    VBlank     = %10000000  ; VBlank has started
    Sprite0Hit = %01000000  ; an opaque OBJ 0 pixel hit an opaque BG pixel
.ENDSCOPE

;;;=========================================================================;;;

;;; PPU scroll position.  Write twice (first X, then Y).
Hw_PpuScroll_w2 = $2005

;;;=========================================================================;;;

;;; PPU address register.  16 bits, write twice (high then low).
Hw_PpuAddr_w2 = $2006

;;; PPU data register.  Auto-increments Hw_PpuAddr_w2 by 1 or 32 on each
;;; access, depending on the value of Hw_PpuCtrl_wo.
Hw_PpuData_rw = $2007

PPUADDR_NAME0 = $2000  ; nametable 0 (upper-left)
PPUADDR_ATTR0 = $23c0  ; attribute table 0
PPUADDR_NAME1 = $2400  ; nametable 1 (upper-right)
PPUADDR_ATTR1 = $27c0  ; attribute table 1
PPUADDR_NAME2 = $2800  ; nametable 2 (lower-left)
PPUADDR_ATTR2 = $2bc0  ; attribute table 2
PPUADDR_NAME3 = $2c00  ; nametable 3 (lower-right)
PPUADDR_ATTR3 = $2fc0  ; attribute table 3
PPUADDR_PALETTES = $3f00  ; https://wiki.nesdev.org/w/index.php/PPU_palettes

;;;=========================================================================;;;

;;; Screen size in pixels:
SCREEN_WIDTH_PX     = 256
SCREEN_HEIGHT_PX    = 240
;;; Screen size in tiles:
SCREEN_WIDTH_TILES  = 32
SCREEN_HEIGHT_TILES = 30
;;; Attribute table size in meta-tiles:
ATTR_WIDTH  = 8
ATTR_HEIGHT = 8

.DEFINE kTileWidthPx  8
.DEFINE kTileHeightPx 8

;;;=========================================================================;;;
