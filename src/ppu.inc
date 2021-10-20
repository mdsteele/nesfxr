;;; See https://wiki.nesdev.org/w/index.php/PPU_registers

;;;=========================================================================;;;

;;; PPU control register (W).
rPPUCTRL = $2000

PPUCTRL_NMI = %10000000  ; enable NMI interrupts for VBlank

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

;;; PPU status (R).  Reading this will clear bit 7 (PPUSTATUS_VBLANK) and will
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

PPUADDR_PALETTES = $3f00  ; https://wiki.nesdev.org/w/index.php/PPU_palettes

;;;=========================================================================;;;
