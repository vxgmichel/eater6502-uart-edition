; Banks for subprograms in the 6502 Ben Eater architecture

; Also defines a copy routine that copies the program to the RAM
; before executing it. This allows the program to reprogram the
; whole EPROM if necessary.

#include "cpu6502.asm"
#include "constants.asm"

; Banks

#bankdef zeropage { #addr 0x0000, #size 0x0100 }
#bankdef stack    { #addr 0x0100, #size 0x0100 }
#bankdef ram      { #addr 0x0200, #size 0x3e00 }
#bankdef program  { #addr 0x3000, #size 0x0f00, #outp 8 * 0x0000 }
#bankdef uart     { #addr 0x4000, #size 0x2000 }
#bankdef iomux    { #addr 0x6000, #size 0x2000 }
#bankdef subprog  { #addr 0x8000, #size 0x0f00 }
#bankdef copyprg  { #addr 0x8f00, #size 0x00fa, #outp 8 * 0x0f00 }
#bankdef subvecs  { #addr 0x8ffa, #size 0x0006, #outp 8 * 0x0ffa }
#bankdef bootprg  { #addr 0xf000, #size 0x0ffa }
#bankdef vectors  { #addr 0xfffa, #size 0x0006 }


#include "zeropage.asm"

#bank program
program:

#bank subprog
rom_subprogram:

#bank copyprg
rom_reset:

  wrw #rom_subprogram 0   ; Write rom program address at address 0-1
  wrw #program 2          ; Write ram program address at address 2-3

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

#bank subvecs
#d16   le(rom_nmi`16) ; Non-maskable interrupt entry point
#d16 le(rom_reset`16) ; Reset entry point
#d16   le(rom_irq`16) ; Maskable interrupt entry point

#bank vectors
boot_nmi: #res 2
boot_reset: #res 2
boot_irq: #res 2
