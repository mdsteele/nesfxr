;;;=========================================================================;;;

;;; Player 1 controller data.  Write #1 here to populate the shift registers
;;; for *both* controllers, then write zero here to allow subsequently reading
;;; one bit at a time from each of Hw_Joypad1_rw and Hw_Joypad2_ro. See
;;; https://wiki.nesdev.org/w/index.php/Standard_controller for details.
Hw_Joypad1_rw = $4016

;;; Player 2 controller data.
Hw_Joypad2_ro = $4017

;;;=========================================================================;;;

.SCOPE bJoypad
    AButton = %10000000
    BButton = %01000000
    Select  = %00100000
    Start   = %00010000
    Up      = %00001000
    Down    = %00000100
    Left    = %00000010
    Right   = %00000001
.ENDSCOPE

;;;=========================================================================;;;
