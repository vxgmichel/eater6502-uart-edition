; Banks for a boot program on the 6502 Ben Eater architecture

#include "cpu6502.asm"
#include "constants.asm"

; Banks

#bankdef zeropage { #addr 0x0000, #size 0x0100 }
#bankdef stack    { #addr 0x0100, #size 0x0100 }
#bankdef ram      { #addr 0x0200, #size 0x3e00 }
#bankdef uart     { #addr 0x4000, #size 0x2000 }
#bankdef iomux    { #addr 0x6000, #size 0x2000 }
#bankdef subprog  { #addr 0x8000, #size 0x0ffa, #outp 8 * 0x0000 }
#bankdef subvecs  { #addr 0x8ffa, #size 0x0006, #outp 8 * 0x0ffa }
#bankdef program  { #addr 0xf000, #size 0x0ffa, #outp 8 * 0x7000 }
#bankdef vectors  { #addr 0xfffa, #size 0x0006, #outp 8 * 0x7ffa }

#include "zeropage.asm"

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

#bank program
bootprogram:

#bank vectors
#d16   le(nmi`16) ; Non-maskable interrupt entry point
#d16 le(reset`16) ; Reset entry point
#d16   le(irq`16) ; Maskable interrupt entry point