;;;=========================================================================;;;

;;; Player 1 controller data (R/W).  Write #1 here to populate the
;;; shift registers for *both* controllers, then write zero here to allow
;;; subsequently reading one bit at a time from each of rJOYPAD1 and rJOYPAD2.
;;; See https://wiki.nesdev.org/w/index.php/Standard_controller for details.
rJOYPAD1 = $4016

;;; Player 2 controller data (R).
rJOYPAD2 = $4017

;;;=========================================================================;;;

BUTTON_A      = %10000000
BUTTON_B      = %01000000
BUTTON_SELECT = %00100000
BUTTON_START  = %00010000
BUTTON_UP     = %00001000
BUTTON_DOWN   = %00000100
BUTTON_LEFT   = %00000010
BUTTON_RIGHT  = %00000001

;;;=========================================================================;;;
