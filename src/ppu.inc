;;; See https://wiki.nesdev.org/w/index.php/PPU_registers

;;;=========================================================================;;;

;;; PPU control register (W).
;;;
;;; When using the MMC3 mapper's IRQ feature, it is best to use 8x8 objects,
;;; and use pattern table $0000 for BG and $1000 for objects.  For details, see
;;; https://wiki.nesdev.org/w/index.php/MMC3#IRQ_Specifics and
;;; https://wiki.nesdev.org/w/index.php/Sprite_size.
rPPUCTRL = $2000

PPUCTRL_NMI    = %10000000  ; enable NMI interrupts for VBlank
PPUCTRL_OBJ16  = %00100000  ; use 8x16 objects (instead of 8x8)
PPUCTRL_BGPT1  = %00010000  ; use pattern table 1 ($1000) for background
PPUCTRL_OBJPT1 = %00001000  ; use pattern table 1 ($1000) for objects
PPUCTRL_INC32  = %00000100  ; increment VRAM addr by 32 per rPPUDATA read/write

;;;=========================================================================;;;

;;; PPU rendering mask (W).  Set this to zero to disable rendering, which will
;;; allow access to the PPU outside of VBlank.
rPPUMASK = $2001

PPUMASK_BLUE  = %10000000  ; emphasize blue
PPUMASK_GREEN = %01000000  ; emphasize green
PPUMASK_RED   = %00100000  ; emphasize red
PPUMASK_OBJM  = %00010000  ; draw objects in main part of screen
PPUMASK_BGM   = %00001000  ; draw background in main part of screen
PPUMASK_OBJL  = %00000100  ; draw objects in leftmost part of screen
PPUMASK_BGL   = %00000010  ; draw background in leftmost part of screen
PPUMASK_GRAY  = %00000001  ; grayscale mode

PPUMASK_OBJ = (PPUMASK_OBJM | PPUMASK_OBJL)  ; draw objects everywhere
PPUMASK_BG =  (PPUMASK_BGM  | PPUMASK_BGL)   ; draw background everywhere
PPUMASK_ALL = (PPUMASK_BG   | PPUMASK_OBJ)   ; draw everything everywhere

;;;=========================================================================;;;

;;; PPU status (R).  Reading this will clear bit 7 (PPUSTATUS_VBLANK), and will
;;; also reset the write-twice latch for rPPUSCROLL and rPPUADDR.
rPPUSTATUS = $2002

PPUSTATUS_VBLANK  = %10000000  ; VBlank has started
PPUSTATUS_SPRITE0 = %01000000  ; sprite 0 hit

;;;=========================================================================;;;

;;; PPU scroll position (W).  Write twice (first X, then Y).
rPPUSCROLL = $2005

;;;=========================================================================;;;

;;; PPU address register (W).  16 bits, write twice (high then low).
rPPUADDR = $2006

;;; PPU data register (R/W).  Auto-increments rPPUADDR by 1 or 32 on each
;;; access, depending on value of rPPUCTRL.
rPPUDATA = $2007

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

;;;=========================================================================;;;
