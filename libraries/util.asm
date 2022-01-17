; Library with useful helpers
#once


; Add functions to program bank
#bank program


; Sleep for A times 10 ms without using interrupts
busy_sleep:
  sta s0          ; Store A in s0
  txa             ; Transfer X to A
  pha             ; And push it onto the stack
  tya             ; Transfer Y to A
  pha             ; And push it onto the stack

  .loop1:         ; Loop until s0 is zero
  ldy #0x14       ; Initialize Y to 256
  .loop2:         ; Outer loop
  ldx #0x00       ; Initialize X to 256
  .loop3:         ; Inner loop
  dex             ; Decrement X
  bne .loop3      ; Jump to inner loop while X is not zero
  dey             ; Decrement Y
  bne .loop2      ; Jump to outer loop while Y is not zero
  dec s0          ; Decrement s0
  bne .loop1      ; Jump to main loop while s0 is not zero

  pla             ; Pull Y from the stack
  tay             ; And transfer it
  pla             ; Pull X from the stack
  tax             ; And transfer it
  rts             ; Return