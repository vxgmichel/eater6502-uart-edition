; Banks for subprograms in the 6502 Ben Eater architecture

#include "cpu6502.asm"
#include "constants.asm"

; Banks

#bankdef zeropage { #addr 0x0000, #size 0x0100 }
#bankdef stack    { #addr 0x0100, #size 0x0100 }
#bankdef ram      { #addr 0x0200, #size 0x3e00 }
#bankdef uart     { #addr 0x4000, #size 0x2000 }
#bankdef iomux    { #addr 0x6000, #size 0x2000 }
#bankdef program  { #addr 0x8000, #size 0x0ffa, #outp 8 * 0x0000 }
#bankdef subvecs  { #addr 0x8ffa, #size 0x0006, #outp 8 * 0x0ffa }
#bankdef romprg   { #addr 0xf000, #size 0x0f00 }
#bankdef bootprg  { #addr 0xff00, #size 0x00fa }
#bankdef vectors  { #addr 0xfffa, #size 0x0006 }

#include "zeropage.asm"

#bank subvecs
#d16   le(nmi`16) ; Non-maskable interrupt entry point
#d16 le(reset`16) ; Reset entry point
#d16   le(irq`16) ; Maskable interrupt entry point
