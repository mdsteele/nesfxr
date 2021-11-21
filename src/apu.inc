;;; See https://wiki.nesdev.org/w/index.php/APU_registers

;;;=========================================================================;;;

rAPUCTRL = $4015

APUCTRL_PULSE1   = %00000001
APUCTRL_PULSE2   = %00000010
APUCTRL_TRIANGLE = %00000100
APUCTRL_NOISE    = %00001000
APUCTRL_DMC      = %00010000

;;;=========================================================================;;;

;;; APU Frame Counter (https://wiki.nesdev.org/w/index.php/APU_Frame_Counter)
rAPUCOUNT = $4017

APUCOUNT_DISABLE = %01000000  ; disable audio IRQ

;;;=========================================================================;;;

rCH1ENV   = $4000
rCH1SWEEP = $4001
rCH1LOW   = $4002
rCH1HIGH  = $4003

;;;=========================================================================;;;
