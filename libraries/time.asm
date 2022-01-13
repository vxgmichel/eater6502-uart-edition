
; Library for time management conversion

TICK = 100                   ; 100 ticks per second
LATCH = 1843200 / 100 - 2    ; Configuation for


; Allocate a buffer for division in the ram
#bank ram
counter: #res 1
time: #res 2


; Add functions to the program
#bank program


; Time interrupt
time_irq:
  pha             ; Push A onto the stack

  lda VIA_IFR     ; Load Interrupt Flag Register
  and #0b01000000 ; Keep timer 1 flag
  beq .done       ; Not a timer 1 interrupt, we're done

  lda VIA_T1C_L   ; Reading T1C_L clears bit 6 in IFR
  dec counter     ; Decrement counter
  bpl .done       ; Counter is still positive, we're done

  lda #TICK - 1   ; Load tick value
  sta counter     ; Write to counter

  .done:
  pla             ; Restore A register
  rts


; Initialize timing interrupt
time_init:
  pha                ; Push A onto the stack

  cli                ; Allow maskable interrupts

  lda #TICK - 1      ; Load tick value
  sta counter        ; Initialize counter

  lda #0b01000000    ; Continuous interrupts on timer 1
  sta VIA_ACR        ; Write configuration

  lda #0b11000000    ; Enable interrupt on timer 1
  sta VIA_IER        ; Write configuration

  wrw #LATCH VIA_T1C ; Write latch and start timer (when higher bytes is written)

  pla                ; Pull A from the stack
  rts                ; Return from subroutine


; Sleep A times 10 ms (first tick might be less than 10 ms)
time_sleep:
  sta s0            ; Store A in s0
  .loop1:           ; Loop until s0 is zero

  lda counter       ; Load counter
  .loop2:           ; Wait until it changes
  cmp counter       ; Compare with itself
  beq .loop2        ; Loop over if unchanged

  dec s0            ; Decrement s0
  bne .loop1        ; Loop over if s0 not zero

  rts               ; Return from subroutine
