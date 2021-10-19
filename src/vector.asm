.INCLUDE "apu.inc"
.INCLUDE "ppu.inc"

.IMPORT Main

;;;=========================================================================;;;

.CODE

;;; Reset interrupt handler, which is called on startup/reset.
.PROC Int_Reset
    sei  ; Disable maskable (IRQ) interrupts.
    cld  ; Disable decimal mode.
    lda #0
    sta rPPUCTRL  ; Disable NMI.
    sta rPPUMASK  ; Disable rendering.
    ;; Disable APU IRQ.
    lda #APUCOUNT_DISABLE
    sta rAPUCOUNT
    ;; Initialize stack.
    ldx #$ff
    txs
    ;; We need to wait for the PPU to warm up before can start the game.  The
    ;; standard strategy for this is to wait for two VBlanks to occur (for
    ;; details, see https://wiki.nesdev.org/w/index.php/Init_code and
    ;; https://wiki.nesdev.org/w/index.php/PPU_power_up_state#Best_practice).
    ;; For now, we'll wait for first VBlank.
    bit rPPUSTATUS  ; Read rPPUSTATUS to implicitly clear the VBlank bit.
    :
    bit rPPUSTATUS  ; Set N (negative) CPU flag equal to value of VBlank bit.
    bpl :-          ; Continue looping until the VBlank bit is set again.
    ;; We've got time to burn until the second VBlank, so this is a good
    ;; opportunity to initialize RAM.  If we were using a mapper, this would be
    ;; a good time to initialize that, too.
    lda #0
    ldx #0
    :
    sta $0000, X
    sta $0100, X
    sta $0200, X
    sta $0300, X
    sta $0400, X
    sta $0500, X
    sta $0600, X
    sta $0700, X
    inx
    bne :-
    ;; TODO: Initialize the shadow OAM.
    ;; Wait for the second VBlank.  After this, the PPU should be warmed up.
    :
    bit rPPUSTATUS
    bpl :-
    ;; Enable NMI.
    lda #PPUCTRL_NMI
    sta rPPUCTRL
    ;; Start the game.
    jmp Main
.ENDPROC

;;; NMI interrupt handler, which is called at the start of VBlank.
.PROC Int_Nmi
    ;; Set BG palette 0.
    lda #>PPUADDR_PALETTES
    ldx #<PPUADDR_PALETTES
    sta rPPUADDR
    stx rPPUADDR
    lda #$0f  ; black
    sta rPPUDATA
    lda #$19  ; dark green
    sta rPPUDATA
    lda #$2a  ; green
    sta rPPUDATA
    lda #$3a  ; light green
    sta rPPUDATA
    ;; Enable rendering.
    lda #PPUMASK_RENDER_ALL
    sta rPPUMASK
    rti
.ENDPROC

;;; IRQ interrupt handler.
.PROC Int_Irq
    rti
.ENDPROC

;;;=========================================================================;;;

.SEGMENT "VECTOR"
    .addr Int_Nmi    ; See https://wiki.nesdev.org/w/index.php/NMI
    .addr Int_Reset
    .addr Int_Irq    ; See https://wiki.nesdev.org/w/index.php/IRQ

;;;=========================================================================;;;
