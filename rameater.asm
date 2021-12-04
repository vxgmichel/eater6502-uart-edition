; Banks for the 6502 Ben Eater architecture

; Also defines a boot routine that copies the program to the RAM
; before executing it. This allows the program to reprogram the
; EPROM if necessary.

#include "constants.asm"

; Banks

#bankdef zeropage { #addr 0x0000, #size 0x0100 }
#bankdef stack    { #addr 0x0100, #size 0x0100 }
#bankdef ram      { #addr 0x0200, #size 0x3e00 }
#bankdef program  { #addr 0x3000, #size 0x0f00, #outp 8 * 0x7000 }
#bankdef uart     { #addr 0x4000, #size 0x2000 }
#bankdef iomux    { #addr 0x6000, #size 0x2000 }
#bankdef subprog  { #addr 0x8000, #size 0x0ffa, #outp 8 * 0x0000 }
#bankdef subvecs  { #addr 0x8ffa, #size 0x0006, #outp 8 * 0x0ffa }
#bankdef romprg   { #addr 0xf000, #size 0x0f00 }
#bankdef bootprg  { #addr 0xff00, #size 0x00fa, #outp 8 * 0x7f00 }
#bankdef vectors  { #addr 0xfffa, #size 0x0006, #outp 8 * 0x7ffa }

#bank program
program:

#bank subprog
subprogram:
subprogram_reset:    ; Dummy subprogram by default
jmp subprogram       ; Loop forever
subprogram_nmi:      ; NMI handler
subprogram_irq:      ; IRQ handler
rti                  ; Return from interrupt


#bank subvecs
subprgm_nmi_vec:   #d16   le(subprogram_nmi`16) ; Non-maskable interrupt entry point
subprgm_reset_vec: #d16 le(subprogram_reset`16) ; Reset entry point
subprgm_irq_vec:   #d16   le(subprogram_irq`16) ; Maskable interrupt entry point

#bank romprg
rom_program:

#bank bootprg
rom_reset:

  lda #rom_program[7:0]   ; Load rom program lower address
  sta 0                   ; At address 0
  lda #rom_program[15:8]  ; Load rom program higher address
  sta 1                   ; At address 1
  lda #program[7:0]       ; Load ram program lower address
  sta 2                   ; At address 2
  lda #program[15:8]      ; Load ram program hight address
  sta 3                   ; At address 4

  ldx #0x10               ; Loop over 16 pages
  .page_copy:             ; ...

  ldy #0x00               ; Loop over 256 bytes
  .byte_copy:             ; ...
  lda (0), y              ; Indirect load from address 0
  sta (2), y              ; Indirect store from address 2
  iny                     ; Increment Y
  bne .byte_copy          ; Loop over

  inc 1                   ; Increment higher rom program address
  inc 3                   ; Increment higher ram program address
  dex                     ; Decrement X
  bne .page_copy          ; Loop over

  jmp reset               ; Jump to the actual reset entry point

rom_nmi:
  jmp nmi

rom_irq:
  jmp irq

#bank vectors
#d16   le(rom_nmi`16) ; Non-maskable interrupt entry point
#d16 le(rom_reset`16) ; Reset entry point
#d16   le(rom_irq`16) ; Maskable interrupt entry point
