; Library for event management (timing and key presses) based on the VIA timer interrupts
#once


TICKS_PER_SEC = 100             ; 100 ticks per second
LATCH_VALUE = 1843200 / 100 - 2 ; Latch configuration for 100 ticks per second with a 1.8432 clock
SECONDS_IN_12H = 60 * 60 * 12   ; Number of seconds in 12 hours

EVENT_TICK = 0b00000001         ; Mask for 10 ms tick event
EVENT_SECOND = 0b00100000       ; Mask for 1 second event
EVENT_HALFDAY = 0b01000000      ; Mask for 1 halfday event

EVENT_LEFT = 0b00000010         ; Mask for left pressed event
EVENT_UP = 0b00001000           ; Mask for up pressed event
EVENT_DOWN = 0b00000100         ; Mask for down pressed event
EVENT_RIGHT = 0b00010000        ; Mask for right pressed event

KEYS_MASK = 0b00011110          ; Mask for keys in PORTA


; Allocate buffers and counters in RAM
#bank ram
event_ticks: #res 1             ; Count 100 ticks of 10 ms
event_seconds: #res 2           ; Count 43200 seconds (12 hours)
event_halfdays: #res 1          ; Count 256 half days (128 days)
event_flags: #res 1             ; Flags for current events
event_last_keys: #res 1         ; Key values at the previous tick


; Add functions to the program
#bank program


; Interrupt handler
event_irq:
  pha                       ; Push A onto the stack
  lda s0                    ; Load s0
  pha                       ; Push it onto the stack

  lda VIA_IFR               ; Load Interrupt Flag Register
  and #0b01000000           ; Keep timer 1 flag
  beq .done                 ; Not a timer 1 interrupt, we're done

  lda PORTA                 ; Read PORTA
  and #KEYS_MASK            ; Only keep the relevant bits
  sta s0                    ; Save in s0

  lda event_last_keys       ; Load keys state
  eor s0                    ; Check difference
  and event_last_keys       ; Only keep press events
  ora event_flags           ; Keep older events
  ora #EVENT_TICK           ; Set the tick event
  sta event_flags           ; Store in keys event

  wrb s0 event_last_keys    ; Save s0 for later tick

  lda VIA_T1C_L             ; Reading T1C_L clears bit 6 in IFR
  inc event_ticks           ; Increment ticks counter
  lda event_ticks           ; Load ticks counter
  cmp #TICKS_PER_SEC        ; Compare with TICKS_PER_SEC
  bne .done                 ; Counter is still positive, we're done

  lda #0                    ; Load zero
  sta event_ticks           ; Reset ticks counter
  inw event_seconds         ; Increment seconds counter

  lda event_flags           ; Load time events
  ora #EVENT_SECOND         ; Set the second event
  sta event_flags           ; Store time events

  lda event_seconds         ; Load lower byte of seconds counter
  cmp #SECONDS_IN_12H[7:0]  ; Compare to lower byte of 12 hours
  bne .done                 ; Continue if equal
  lda event_seconds + 1     ; Load higher byte of seconds counter
  cmp #SECONDS_IN_12H[15:8] ; Countinue if equal
  bne .done                 ; Continue if equal

  wrw #0 event_seconds      ; Reset seconds counter
  inc event_halfdays        ; Increment half days

  lda event_flags           ; Load time events
  ora #EVENT_HALFDAY        ; Set the halfday event
  sta event_flags           ; Store time events

  .done:
  pla                       ; Restore s0 from stack
  sta s0                    ; Save it
  pla                       ; Restore A register
  rts                       ; Return from subroutine


; Initialize interrupt handling
event_init:
  pha                      ; Push A onto the stack
  sei                      ; Do not allow interrupt

  wrb #0 event_ticks       ; Initialize tick counter
  wrw #0 event_seconds     ; Initialize second counter
  wrb #0 event_halfdays    ; Initialize halfday counter

  wrb #0 event_flags       ; Initialize event flags
  lda PORTA                ; Load port A
  and #KEYS_MASK           ; Keep only the keys
  sta event_last_keys      ; Initialize last keys

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


; Quit interrupt handling
event_quit:
  pha                      ; Push A onto the stack

  lda #0b01000000          ; Disable interrupt on timer 1
  sta VIA_IER              ; Write configuration

  lda #0b00000000          ; Disable timer 1
  sta VIA_ACR              ; Write configuration
  lda VIA_T1C_L            ; Reading T1C_L clears bit 6 in IFR

  wrb #0 event_ticks       ; Reset tick counter
  wrw #0 event_seconds     ; Reset second counter
  wrb #0 event_halfdays    ; Reset halfday counter

  wrb #0 event_flags       ; Reset event flags
  wrb #0 event_last_keys   ; Reset last keys

  pla                      ; Pull A from the stack
  rts                      ; Return from subroutine


; Sleep A times 10 ms (first tick might be less than 10 ms)
event_sleep:
  sta s0            ; Store A in s0
  .loop1:           ; Loop until s0 is zero

  lda event_ticks   ; Load ticks counter
  .loop2:           ; Wait until it changes
  cmp event_ticks   ; Compare with itself
  beq .loop2        ; Loop over if unchanged

  dec s0            ; Decrement s0
  bne .loop1        ; Loop over if s0 not zero

  rts               ; Return from subroutine


; Pop events
event_pop:
  php                ; Push processor status on the stack
  sei                ; Do not allow interrupt

  wrb event_flags s0 ; Load time events in s0
  wrb #0 event_flags ; Reset time events
  lda s0             ; Load s0

  plp                ; Restore processor status
  rts                ; Return from subroutine