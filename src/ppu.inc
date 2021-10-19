;;; See https://wiki.nesdev.org/w/index.php/PPU_registers

;;;=========================================================================;;;

rPPUCTRL = $2000

PPUCTRL_NMI = %10000000  ; enable NMI interrupts for VBlank

;;;=========================================================================;;;

rPPUMASK = $2001

PPUMASK_RENDER_ALL = %00011110

;;;=========================================================================;;;

rPPUSTATUS = $2002

PPUSTATUS_VBLANK  = %10000000  ; VBlank has started
PPUSTATUS_SPRITE0 = %01000000  ; sprite 0 hit

;;;=========================================================================;;;

;;; PPU address register (W).  16 bits, write twice (high then low).
rPPUADDR = $2006

;;; PPU data register (R/W).  Auto-increments rPPUADDR by 1 or 32 on each
;;; access, depending on value of rPPUCTRL.
rPPUDATA = $2007

PPUADDR_PALETTES = $3f00  ; https://wiki.nesdev.org/w/index.php/PPU_palettes

;;;=========================================================================;;;
