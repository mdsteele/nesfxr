.INCLUDE "joypad.inc"

;;;=========================================================================;;;

.ZEROPAGE

;;; ButtonsHeld: A bitfield indicating which player 1 buttons are currently
;;; being held.
.EXPORTZP Zp_P1ButtonsHeld_u8
Zp_P1ButtonsHeld_u8: .res 1

;;; ButtonsPressed: A bitfield indicating which player 1 buttons have been
;;; newly pressed since the previous call to Func_UpdateButtons.
.EXPORTZP Zp_P1ButtonsPressed_u8
Zp_P1ButtonsPressed_u8: .res 1

;;;=========================================================================;;;

.CODE

;;; Helper function for Func_UpdateButtons.  Reads buttons from joypad and
;;; populates Zp_P1ButtonsHeld_u8.
;;; @preserve X, Y
.PROC Func_ReadButtons
    ;; This function's code comes almost directly from
    ;; https://wiki.nesdev.org/w/index.php/Controller_reading_code.
    lda #1
    ;; While the strobe bit is set, buttons will be continuously reloaded.
    ;; This means that reading from rJOYPAD1 will only return the state of the
    ;; first button: button A.
    sta rJOYPAD1
    sta Zp_P1ButtonsHeld_u8  ; Initialize with a 1 bit, to be used later.
    lsr a  ; now A is 0
    ;; By storing 0 into rJOYPAD1, the strobe bit is cleared and the reloading
    ;; stops.  This allows all 8 buttons (newly reloaded) to be read from
    ;; JOYPAD1.
    sta rJOYPAD1
    @loop:
    lda rJOYPAD1
    lsr a                    ; bit 0 -> Carry
    rol Zp_P1ButtonsHeld_u8  ; Carry -> bit 0; bit 7 -> Carry
    bcc @loop  ; Stop when the initial 1 bit is finally shifted into Carry.
    rts
.ENDPROC

;;; Reads buttons from joypad and populates Zp_P1ButtonsHeld_u8 and
;;; Zp_P1ButtonsPressed_u8.
.EXPORT Func_UpdateButtons
.PROC Func_UpdateButtons
    ;; Store the buttons *not* held last frame in Y.
    lda Zp_P1ButtonsHeld_u8
    eor #$ff
    tay
    ;; Apparently, when using APU DMC playback, controller reading will
    ;; sometimes glitch.  One standard workaround (used by e.g. Super Mario
    ;; Bros. 3) is to read the controller repeatedly until you get the same
    ;; result twice in a row.  This part of the code is adapted from
    ;; https://wiki.nesdev.org/w/index.php/Controller_reading_code.
    jsr Func_ReadButtons  ; preserves X and Y
    @rereadLoop:
    ldx Zp_P1ButtonsHeld_u8
    jsr Func_ReadButtons  ; preserves X and Y
    txa
    cmp Zp_P1ButtonsHeld_u8
    bne @rereadLoop
    ;; Now that we have a reliable value for Zp_P1ButtonsHeld_u8, we can set
    ;; Zp_P1ButtonsPressed_u8 to the buttons that are newly held this frame.
    tya
    and Zp_P1ButtonsHeld_u8
    sta Zp_P1ButtonsPressed_u8
    rts
.ENDPROC

;;;=========================================================================;;;
