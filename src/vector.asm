.INCLUDE "apu.inc"
.INCLUDE "cpu.inc"
.INCLUDE "oam.inc"
.INCLUDE "ppu.inc"

.IMPORT Func_OamClear
.IMPORT Main
.IMPORT Ram_ShadowOam_sObj_arr64

;;;=========================================================================;;;

.ZEROPAGE

;;; NmiReady: Set this to 1 to signal that Ram_ShadowOam_sObj_arr64 is ready
;;; to be consumed by the NMI handler.  The NMI handler will set it back to 0
;;; once the data is transferred.
Zp_NmiReady_bool: .res 1

;;; PpuMask: The NMI handler will copy this to Hw_PpuMask_wo when
;;; Zp_NmiReady_bool is set.
.EXPORTZP Zp_PpuMask_u8
Zp_PpuMask_u8: .res 1

;;; ScrollX/ScrollY: The NMI handler will copy these to Hw_PpuScroll_w2 when
;;; Zp_NmiReady_bool is set.
.EXPORTZP Zp_ScrollX_u8, Zp_ScrollY_u8
Zp_ScrollX_u8: .res 1
Zp_ScrollY_u8: .res 1

;;; BaseName: The base nametable index to scroll relative to (0-3).  The NMI
;;; handler will copy this to the lower two bits of Hw_PpuCtrl_wo when
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
    sei  ; disable maskable (IRQ) interrupts
    cld  ; disable BCD mode (doesn't matter for NES, but may for debuggers)
    ;; Disable VBlank NMI.
    ldx #0
    stx Hw_PpuCtrl_wo   ; disable VBlank NMI
    ;; Initialize stack pointer.
    dex  ; now x is $ff
    txs
    ;; Disable APU IRQ.
    lda #bApuCount::DisableIrq
    sta Hw_ApuCount_wo
_WaitForFirstVBlank:
    ;; We need to wait for the PPU to warm up before can start the game.  The
    ;; standard strategy for this is to wait for two VBlanks to occur (for
    ;; details, see https://wiki.nesdev.org/w/index.php/Init_code and
    ;; https://wiki.nesdev.org/w/index.php/PPU_power_up_state#Best_practice).
    ;; For now, we'll wait for first VBlank.
    bit Hw_PpuStatus_ro  ; Reading this implicitly clears the VBlank bit.
    @loop:
    .assert bPpuStatus::VBlank = bProc::Negative, error
    bit Hw_PpuStatus_ro  ; Set N (negative) CPU flag to value of VBlank bit.
    bpl @loop            ; Continue looping until the VBlank bit is set again.
_DisableRendering:
    ;; Now that we're in VBlank, we can disable rendering.  On a true reset,
    ;; the PPU won't be warmed up yet and will ignore these writes, but that's
    ;; okay because on a true reset, rendering is initially disabled anyway.
    ;; On a soft reset, we want to disable rendering during VBlank.
    lda #0
    sta Hw_PpuMask_wo   ; disable rendering
_InitializeRam:
    ;; We've got time to burn until the second VBlank, so this is a good
    ;; opportunity to initialize RAM.  If we were using a mapper, this would be
    ;; a good time to initialize that, too.
    lda #0
    ldx #0
    @loop:
    sta $0000, x
    sta $0100, x
    sta $0200, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    inx
    bne @loop
    jsr Func_OamClear
_WaitForSecondVBlank:
    ;; Wait for the second VBlank.  After this, the PPU should be warmed up.
    @loop:
    bit Hw_PpuStatus_ro
    bpl @loop
_Finish:
    ;; Enable NMI.
    lda #bPpuCtrl::EnableNmi
    sta Hw_PpuCtrl_wo
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
    sta Hw_OamAddr_wo
    .assert <Ram_ShadowOam_sObj_arr64 = 0, error
    lda #>Ram_ShadowOam_sObj_arr64
    sta Hw_OamDma_wo
_TransferPpuData:
    bit Hw_PpuStatus_ro  ; Reset the write-twice latch.
    ldx #0
    @entryLoop:
    ldy Ram_PpuTransfer_start, x
    beq @done
    inx
    .repeat 2
    lda Ram_PpuTransfer_start, x
    sta Hw_PpuAddr_w2
    inx
    .endrepeat
    @dataLoop:
    lda Ram_PpuTransfer_start, x
    sta Hw_PpuData_rw
    inx
    dey
    bne @dataLoop
    beq @entryLoop  ; unconditional
    @done:
_FinishUpdatingPpu:
    ;; Update other PPU registers.  Note that writing to Hw_PpuAddr_w2 (as
    ;; above) can corrupt the scroll position, so we must write Hw_PpuScroll_w2
    ;; afterwards.  See https://wiki.nesdev.org/w/index.php/PPU_scrolling.
    lda Zp_ScrollX_u8
    sta Hw_PpuScroll_w2
    lda Zp_ScrollY_u8
    sta Hw_PpuScroll_w2
    lda Zp_BaseName_u2
    ora #bPpuCtrl::EnableNmi | bPpuCtrl::ObjPat1
    sta Hw_PpuCtrl_wo
    lda Zp_PpuMask_u8
    sta Hw_PpuMask_wo
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
