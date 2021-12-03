; Banks for the 6502 Ben Eater architecture

#include "constants.asm"


; Banks

#bankdef zeropage { #addr 0x0,    #size 0x100 }
#bankdef stack    { #addr 0x100,  #size 0x100 }
#bankdef ram      { #addr 0x200,  #size 0x3e00 }
#bankdef uart     { #addr 0x4000, #size 0x2000 }
#bankdef iomux    { #addr 0x6000, #size 0x2000 }
#bankdef program  { #addr 0x8000, #size 0x7ffa, #outp 8 * 0x0000 }
#bankdef vectors  { #addr 0xfffa, #size 0x6,    #outp 8 * 0x7ffa }

#bank vectors
#d16   nmi[7:0] @   nmi[15:8] ; Non-maskable interrupt entry point
#d16 reset[7:0] @ reset[15:8] ; Reset entry point
#d16   irq[7:0] @   irq[15:8] ; Maskable interrupt entry point