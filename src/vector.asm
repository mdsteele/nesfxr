.INCLUDE "apu.inc"
.INCLUDE "oam.inc"
.INCLUDE "ppu.inc"

.IMPORT Func_OamClear, Main, Ram_ShadowOam_oama_arr64

;;;=========================================================================;;;

.ZEROPAGE

;;; NmiReady: Set this to 1 to signal that Ram_ShadowOam_oama_arr64 is ready
;;; to be consumed by the NMI handler.  The NMI handler will set it back to 0
;;; once the data is transferred.
Zp_NmiReady_bool: .res 1

;;; PpuMask: The NMI handler will copy this to rPPUMASK when Zp_NmiReady_bool
;;; is set.
.EXPORTZP Zp_PpuMask_u8
Zp_PpuMask_u8: .res 1

;;; ScrollX/ScrollY: The NMI handler will copy these to rPPUSCROLL when
;;; Zp_NmiReady_bool is set.
.EXPORTZP Zp_ScrollX_u8, Zp_ScrollY_u8
Zp_ScrollX_u8: .res 1
Zp_ScrollY_u8: .res 1

;;; BaseName: The base nametable index to scroll relative to (0-3).  The NMI
;;; handler will copy this to the lower two bits of rPPUCTRL when
;;; Zp_NmiReady_bool is set.
.EXPORTZP Zp_BaseName_u2
Zp_BaseName_u2: .res 1

.EXPORTZP Zp_PpuTransferLen_u8
Zp_PpuTransferLen_u8: .res 1

;;;=========================================================================;;;

.BSS

;;; PpuTransfer: Storage for data that the NMI hanlder should transfer to the
;;; PPU the next time that Zp_NmiReady_bool is set.  Consists of zero or more
;;; entries, terminated by a zero byte, where each entry consists of:
;;;     - Length (1 byte, must be nonzero)
;;;     - Destination PPU address (2 bytes, *big*-endian)
;;;     - Data (length bytes)
.EXPORT Ram_PpuTransfer_start
Ram_PpuTransfer_start: .res $80

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
    sta $0000, x
    sta $0100, x
    sta $0200, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    inx
    bne :-
    jsr Func_OamClear
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
    ;; Save registers.  (Note that the interrupt automatically saves processor
    ;; flags, so we don't need a php instruction here.)
    pha
    txa
    pha
    tya
    pha
    ;; Check if the CPU is ready to transfer data to the PPU.
    lda Zp_NmiReady_bool
    beq _DoneUpdatingPpu
_TransferOamData:
    lda #0
    sta rOAMADDR
    .assert <Ram_ShadowOam_oama_arr64 = 0, error
    lda #>Ram_ShadowOam_oama_arr64
    sta rOAMDMA
_TransferPpuData:
    bit rPPUSTATUS  ; Reset the write-twice latch for rPPUADDR and rPPUSCROLL.
    ldx #0
    @entryLoop:
    ldy Ram_PpuTransfer_start, x
    beq @done
    inx
    .repeat 2
    lda Ram_PpuTransfer_start, x
    sta rPPUADDR
    inx
    .endrepeat
    @dataLoop:
    lda Ram_PpuTransfer_start, x
    sta rPPUDATA
    inx
    dey
    bne @dataLoop
    beq @entryLoop  ; unconditional
    @done:
_FinishUpdatingPpu:
    ;; Update other PPU registers.  Note that rPPUSCROLL is a write-twice
    ;; register (first X, then Y).  Also note that writing to rPPUADDR (as
    ;; above) can corrupt the scroll position, so we need to write rPPUSCROLL
    ;; afterwards.  See https://wiki.nesdev.org/w/index.php/PPU_scrolling.
    lda Zp_ScrollX_u8
    sta rPPUSCROLL
    lda Zp_ScrollY_u8
    sta rPPUSCROLL
    lda Zp_BaseName_u2
    ora #(PPUCTRL_NMI | PPUCTRL_OBJPT1)
    sta rPPUCTRL
    lda Zp_PpuMask_u8
    sta rPPUMASK
    ;; Mark the PPU transfer buffer as empty and indicate that we are done
    ;; updating the PPU.
    lda #0
    sta Zp_PpuTransferLen_u8
    sta Zp_NmiReady_bool
_DoneUpdatingPpu:
    ;; Restore registers and return.  (Note that the rti instruction
    ;; automatically restores processor flags, so we don't need a plp
    ;; instruction here.)
    pla
    tay
    pla
    tax
    pla
    rti
.ENDPROC

;;; IRQ interrupt handler.
.PROC Int_Irq
    rti
.ENDPROC

;;; Signals that shadow OAM/PPU data is ready to be transferred, then waits for
;;; the next NMI to complete.
.EXPORT Func_ProcessFrame
.PROC Func_ProcessFrame
    ;; Zero-terminate the PPU transfer buffer.
    ldx Zp_PpuTransferLen_u8
    lda #0
    sta Ram_PpuTransfer_start, x
    ;; Tell the NMI handler that we are ready for it to transfer data, then
    ;; wait until it finishes.
    inc Zp_NmiReady_bool
    @loop:
    lda Zp_NmiReady_bool
    bne @loop
    rts
.ENDPROC

;;;=========================================================================;;;

.SEGMENT "VECTOR"
    .addr Int_Nmi    ; See https://wiki.nesdev.org/w/index.php/NMI
    .addr Int_Reset
    .addr Int_Irq    ; See https://wiki.nesdev.org/w/index.php/IRQ

;;;=========================================================================;;;
