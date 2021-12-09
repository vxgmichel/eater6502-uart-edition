; Empty program

#include "map/subeater.asm"

#bank program
reset:          ; Dummy program
  jmp reset     ; Loop forever
nmi:            ; NMI handler
irq:            ; IRQ handler
  rti           ; Return from interrupt

