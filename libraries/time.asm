
; Library for time management

TICKS_PER_SEC = 100             ; 100 ticks per second
LATCH_VALUE = 1843200 / 100 - 2 ; Latch configuration for 100 ticks per second with a 1.8432 clock


EVENT_TICK = 0b00000001      ; Mask for for 10 ms tick event
EVENT_SECOND = 0b00000010    ; Mask for for 1 s tick event

; Allocate a buffer for division in the ram
#bank ram
time_ticks: #res 1
time_seconds: #res 2
time_events: #res 1


; Add functions to the program
#bank program


; Time interrupt
time_irq:
  pha               ; Push A onto the stack

  lda VIA_IFR       ; Load Interrupt Flag Register
  and #0b01000000   ; Keep timer 1 flag
  beq .done         ; Not a timer 1 interrupt, we're done

  lda time_events   ; Load time events
  ora #EVENT_TICK   ; Set the tick event
  sta time_events   ; Save time events

  lda VIA_T1C_L     ; Reading T1C_L clears bit 6 in IFR
  inc time_ticks    ; Increment ticks counter
  cmp TICKS_PER_SEC ; Compare with TICKS_PER_SEC
  bne .done         ; Counter is still positive, we're done

  lda #0            ; Load zero
  sta time_ticks    ; Reset ticks counter
  inw time_seconds  ; Increment seconds counter

  lda time_events   ; Load time events
  ora #EVENT_SECOND ; Set the second event
  sta time_events   ; Store time events

  .done:
  pla             ; Restore A register
  rts


; Initialize timing interrupt
time_init:
  pha                      ; Push A onto the stack


  wrb #0 time_ticks        ; Load tick value
  wrw #0 time_seconds      ; Initialize ticks counter

  lda #0b01000000          ; Continuous interrupts on timer 1
  sta VIA_ACR              ; Write configuration

  lda #0b11000000          ; Enable interrupt on timer 1
  sta VIA_IER              ; Write configuration

  wrw #LATCH_VALUE VIA_T1C ; Write latch and start timer (when higher bytes is written)

  cli                      ; Allow maskable interrupts

  pla                      ; Pull A from the stack
  rts                      ; Return from subroutine


; Quit timing handling
time_quit:
  pha                      ; Push A onto the stack

  lda #0b01000000          ; Disable interrupt on timer 1
  sta VIA_IER              ; Write configuration

  lda #0b00000000          ; Disable timer 1
  sta VIA_ACR              ; Write configuration

  wrb #0 time_ticks        ; Reset tick value
  wrw #0 time_seconds      ; Reset ticks counter

  pla                      ; Pull A from the stack
  rts                      ; Return from subroutine


; Sleep A times 10 ms (first tick might be less than 10 ms)
time_sleep:
  sta s0            ; Store A in s0
  .loop1:           ; Loop until s0 is zero

  lda time_ticks    ; Load ticks counter
  .loop2:           ; Wait until it changes
  cmp time_ticks    ; Compare with itself
  beq .loop2        ; Loop over if unchanged

  dec s0            ; Decrement s0
  bne .loop1        ; Loop over if s0 not zero

  rts               ; Return from subroutine


; Pop time events
time_pop_events:
  php               ; Push processor status on the stack
  sei               ; Do not allow interrupt

  wrb time_events s0 ; Load time events in s0
  wrb #0 time_events ; Reset time events
  lda s0             ; Load s0

  plp               ; Restore processor status
  rts               ; Return from subroutine


; Sleep for A times 10 ms without using interrupts
time_busy_sleep:
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
