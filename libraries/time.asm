; Library for time management
#once
#include "./math.asm"
#include "./decimal.asm"


TICKS_PER_SEC = 100             ; 100 ticks per second
LATCH_VALUE = 1843200 / 100 - 2 ; Latch configuration for 100 ticks per second with a 1.8432 clock
SECONDS_IN_12H = 60 * 60 * 12

EVENT_TICK = 0b00000001      ; Mask for for 10 ms tick event
EVENT_SECOND = 0b00100000    ; Mask for for 1 s tick event

EVENT_LEFT = 0b00000010
EVENT_UP = 0b00001000
EVENT_DOWN = 0b00000100
EVENT_RIGHT = 0b00010000


; Allocate buffers and counters in RAM
#bank ram
time_ticks: #res 1
time_seconds: #res 2
time_events: #res 1
time_keys: #res 1
hms_buffer: #res 6
hms_string: #res 9


; Add functions to the program
#bank program


; Time interrupt
time_irq:
  pha                       ; Push A onto the stack
  lda s0                    ; Load s0
  pha                       ; Push it onto the stack

  lda VIA_IFR               ; Load Interrupt Flag Register
  and #0b01000000           ; Keep timer 1 flag
  beq .done                 ; Not a timer 1 interrupt, we're done

  lda PORTA                 ; Read PORTA
  and #0b00011110           ; Only keep the relevant bits
  sta s0                    ; Save in s0

  lda time_keys             ; Load keys state
  eor s0                    ; Check difference
  and time_keys             ; Only keep press events
  ora time_events           ; Keep older events
  ora #EVENT_TICK           ; Set the tick event
  sta time_events           ; Store in keys event

  wrb s0 time_keys          ; Save s0 for later tick

  lda VIA_T1C_L             ; Reading T1C_L clears bit 6 in IFR
  inc time_ticks            ; Increment ticks counter
  lda time_ticks            ; Load ticks counter
  cmp #TICKS_PER_SEC        ; Compare with TICKS_PER_SEC
  bne .done                 ; Counter is still positive, we're done

  lda #0                    ; Load zero
  sta time_ticks            ; Reset ticks counter
  inw time_seconds          ; Increment seconds counter

  lda time_events           ; Load time events
  ora #EVENT_SECOND         ; Set the second event
  sta time_events           ; Store time events

  lda time_seconds          ; Load lower byte of seconds counter
  cmp #SECONDS_IN_12H[7:0]  ; Compare to lower byte of 12 hours
  bne .done                 ; Continue if equal
  lda time_seconds + 1      ; Load higher byte of seconds counter
  cmp #SECONDS_IN_12H[15:8] ; Countinue if equal
  bne .done                 ; Continue if equal

  wrw #0 time_seconds       ; Reset seconds counter

  .done:
  pla                       ; Restore s0 from stack
  sta s0                    ; Save it
  pla                       ; Restore A register
  rts                       ; Return from subroutine


; Initialize timing interrupt
time_init:
  pha                      ; Push A onto the stack
  sei                      ; Do not allow interrupt

  wrb #0 time_ticks        ; Load tick value
  wrw #0 time_seconds      ; Initialize ticks counter

  lda #0b01000000          ; Continuous interrupts on timer 1
  sta VIA_ACR              ; Write configuration

  lda VIA_IER              ; Load IER configuration
  ora #0b11000000          ; Enable interrupt on timer 1
  sta VIA_IER              ; Write configuration

  wrw #LATCH_VALUE VIA_T1C ; Write latch and start timer (when higher bytes is written)
  lda VIA_T1C_L            ; Reading T1C_L clears bit 6 in IFR

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
  lda VIA_T1C_L            ; Reading T1C_L clears bit 6 in IFR

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


; Add seconds in a0-a1 to current time
time_add_seconds:
  php                       ; Push processor status on the stack
  sei                       ; Do not allow interrupt

  clc                       ; Clear carry for addition
  lda a0                    ; Load argument lower byte
  adc time_seconds          ; Add current time lower byte
  sta time_seconds          ; Store result
  lda a1                    ; Load argument higher byte
  adc time_seconds + 1      ; Add current time higher byte
  sta time_seconds + 1      ; Store result

  sec                       ; Prepare carry for subtraction
  lda time_seconds          ; Load lower byte of seconds counter
  sbc #SECONDS_IN_12H[7:0]  ; Subtract to lower byte of 12 hours
  sta s0                    ; Store in s0
  lda time_seconds + 1      ; Load higher byte of seconds counter
  sbc #SECONDS_IN_12H[15:8] ; Subtract to higher byte of 12 hours
  sta s1                    ; Store in s1
  bcc .done                 ; Continue if negative
  wrw s0 time_seconds       ; Write new value

  .done:
  plp                       ; Restore processor status
  rts                       ; Return from subroutine


; Subtract seconds in a0-a1 to current time
time_sub_seconds:
  php                       ; Push processor status on the stack
  sei                       ; Do not allow interrupt

  sec                       ; Prepare carry for subtraction
  lda time_seconds          ; Load current time lower byte
  sbc a0                    ; Subtract argument lower byte
  sta time_seconds          ; Store result
  lda time_seconds + 1      ; Load current time higher byte
  sbc a1                    ; Subtract argument higher byte
  sta time_seconds + 1      ; Store result
  bcs .done                 ; Done if positive

  clc                       ; Prepare carry for addition
  lda time_seconds          ; Load lower byte of seconds counter
  adc #SECONDS_IN_12H[7:0]  ; Add to lower byte of 12 hours
  sta time_seconds          ; Store in s0
  lda time_seconds + 1      ; Load higher byte of seconds counter
  adc #SECONDS_IN_12H[15:8] ; Add to higher byte of 12 hours
  sta time_seconds + 1      ; Store in s1

  .done:
  plp                       ; Restore processor status
  rts                       ; Return from subroutine


; Synchronize to the closest second
time_sync:
  php                       ; Push processor status on the stack
  sei                       ; Do not allow interrupt

  lda time_ticks            ; Load current ticks
  cmp TICKS_PER_SEC / 2     ; Compare to half range
  bpl .round_down           ; Round down

  .round_up:
  wrb #99 time_ticks        ; Increment second at the next tick
  jmp .done                 ; We're done

  .round_down:
  wrb #0 time_ticks         ; Reset current second

  .done:
  plp                       ; Restore processor status
  rts                       ; Return from subroutine


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


; Return the current time as hour, minute and seconds
time_hours_minutes_seconds:
  wrw #0 hms_buffer + 0    ; Write 0 in a0
  wrw #0 hms_buffer + 2    ; Write 0 in a2
  wrw #0 hms_buffer + 4    ; Write 0 in a4

  php                      ; Push processor status on the stack
  sei                      ; Do not allow interrupt
  wrw time_seconds a0      ; Write seconds to a0
  plp                      ; Restore processor status

  clc                      ; Clear carry bit
  lda #3600[7:0]           ; Load lower byte of 3600
  adc a0                   ; Add to a0
  sta a0                   ; And write back
  lda #3600[15:8]          ; Load higher byte of 3600
  adc a1                   ; Add to a1
  sta a1                   ; And write back

  wrw #60 a2               ; Write divisor to a2
  wrw #hms_buffer a4       ; Write hms buffer address to a2
  jsr successive_division  ; Perform divisions

  wrw hms_buffer + 0 a4    ; Write seconds in a4
  wrw hms_buffer + 2 a2    ; Write minutes in a2
  wrw hms_buffer + 4 a0    ; Write hours in a0
  rts                      ; Return from subroutine


; Return the current time as a string
time_as_str:
  lda r0
  pha
  lda r1
  pha
  lda r2
  pha
  lda r3
  pha

  jsr time_hours_minutes_seconds

  wrw a2 r0
  wrw a4 r2

  wrw #hms_string a2
  jsr to_base10

  lda hms_string + 1
  bne .skip1
  wrb hms_string + 0 hms_string + 1
  wrb #"0" hms_string + 0
  .skip1:

  wrb #":" hms_string + 2

  wrw r0 a0
  wrw #(hms_string + 3) a2
  jsr to_base10

  lda hms_string + 4
  bne .skip2
  wrb hms_string + 3 hms_string + 4
  wrb #"0" hms_string + 3
  .skip2:

  wrb #":" hms_string + 5

  wrw r2 a0
  wrw #(hms_string + 6) a2
  jsr to_base10

  lda hms_string + 7
  bne .skip3
  wrb hms_string + 6 hms_string + 7
  wrb #"0" hms_string + 6
  .skip3:

  wrb #"\0" hms_string + 8
  wrw #hms_string a0

  pla
  sta r3
  pla
  sta r2
  pla
  sta r1
  pla
  sta r0
  rts
