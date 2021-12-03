; Banks for the 6502 Ben Eater architecture

; Also defines a boot routine that copies the program to the RAM
; before executing it. This allows the program to reprogram the
; EPROM if necessary.

#include "constants.asm"

; Banks
PAGE = 0x0100

#bankdef zeropage { #addr 0x0000, #size 0x0100 }
#bankdef stack    { #addr 0x0100, #size 0x0100 }
#bankdef ram      { #addr 0x0200, #size 0x3e00 }
#bankdef program  { #addr 0x3e00, #size 0x0200, #outp 8 * 0x7d00 }
#bankdef uart     { #addr 0x4000, #size 0x2000 }
#bankdef iomux    { #addr 0x6000, #size 0x2000 }
#bankdef romprg   { #addr 0xfd00, #size 0x0200 }
#bankdef bootprg  { #addr 0xff00, #size 0x00fa, #outp 8 * 0x7f00 }
#bankdef vectors  { #addr 0xfffa, #size 0x0006, #outp 8 * 0x7ffa }

#bank program
program:

#bank romprg
romprg_page0: #res 256
romprg_page1: #res 256

#bank bootprg
rom_reset:

  ; Copy program first page to ram
  ldx #0x00
  .ram_copy0:
  lda romprg_page0, x
  sta program, x
  inx
  bne .ram_copy0

  ; Copy program second page to ram
  ldx #0x00
  .ram_copy1:
  lda romprg_page1, x
  sta program + PAGE, x
  inx
  bne .ram_copy1

  ; Jump to the actual reset entry point
  jmp reset

rom_nmi:
  jmp nmi

rom_irq:
  jmp irq

#bank vectors
#d16   rom_nmi[7:0] @   rom_nmi[15:8] ; Non-maskable interrupt entry point
#d16 rom_reset[7:0] @ rom_reset[15:8] ; Reset entry point
#d16   rom_irq[7:0] @   rom_irq[15:8] ; Maskable interrupt entry point
