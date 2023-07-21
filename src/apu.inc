;;; See https://wiki.nesdev.org/w/index.php/APU_registers

;;;=========================================================================;;;

.ENUM eChannel
    Pulse1
    Pulse2
    Triangle
    Noise
    Dmc
    NUM_VALUES
.ENDENUM

.ENUM eDuty
    _1_8
    _1_4
    _1_2
    _3_4
    NUM_VALUES
.ENDENUM

;;;=========================================================================;;;

Hw_ApuStatus_rw = $4015

.SCOPE bApuStatus
    DmcInterrupt   = %10000000
    FrameInterrupt = %01000000
    Dmc            = %00010000
    Noise          = %00001000
    Triangle       = %00000100
    Pulse2         = %00000010
    Pulse1         = %00000001
.ENDSCOPE

;;;=========================================================================;;;

;;; APU Frame Counter (https://www.nesdev.org/wiki/APU_Frame_Counter)
Hw_ApuCount_wo = $4017

.SCOPE bApuCount
    Seq5Step   = %10000000
    DisableIrq = %01000000  ; if set, frame counter IRQs will not be generated
.ENDSCOPE

;;;=========================================================================;;;

rCH1ENV   = $4000
rCH1SWEEP = $4001
rCH1LOW   = $4002
rCH1HIGH  = $4003

rCHNENV   = $400c
rCHNLOW   = $400e
rCHNHIGH  = $400f

;;;=========================================================================;;;
