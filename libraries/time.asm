; Library for time management
#once
#include "./math.asm"
#include "./event.asm"
#include "./decimal.asm"


; Allocate buffers in RAM
#bank ram
hms_buffer: #res 6
hms_string: #res 9


; Add functions to the program
#bank program


; Add seconds in a0-a1 to current time
time_add_seconds:
  php                       ; Push processor status on the stack
  sei                       ; Do not allow interrupt

  clc                       ; Clear carry for addition
  lda a0                    ; Load argument lower byte
  adc event_seconds         ; Add current time lower byte
  sta event_seconds         ; Store result
  lda a1                    ; Load argument higher byte
  adc event_seconds + 1     ; Add current time higher byte
  sta event_seconds + 1     ; Store result

  sec                       ; Prepare carry for subtraction
  lda event_seconds         ; Load lower byte of seconds counter
  sbc #SECONDS_IN_12H[7:0]  ; Subtract to lower byte of 12 hours
  sta s0                    ; Store in s0
  lda event_seconds + 1     ; Load higher byte of seconds counter
  sbc #SECONDS_IN_12H[15:8] ; Subtract to higher byte of 12 hours
  sta s1                    ; Store in s1
  bcc .done                 ; Continue if negative
  wrw s0 event_seconds      ; Write new value

  .done:
  plp                       ; Restore processor status
  rts                       ; Return from subroutine


; Subtract seconds in a0-a1 to current time
time_sub_seconds:
  php                       ; Push processor status on the stack
  sei                       ; Do not allow interrupt

  sec                       ; Prepare carry for subtraction
  lda event_seconds         ; Load current time lower byte
  sbc a0                    ; Subtract argument lower byte
  sta event_seconds         ; Store result
  lda event_seconds + 1     ; Load current time higher byte
  sbc a1                    ; Subtract argument higher byte
  sta event_seconds + 1     ; Store result
  bcs .done                 ; Done if positive

  clc                       ; Prepare carry for addition
  lda event_seconds         ; Load lower byte of seconds counter
  adc #SECONDS_IN_12H[7:0]  ; Add to lower byte of 12 hours
  sta event_seconds         ; Store in s0
  lda event_seconds + 1     ; Load higher byte of seconds counter
  adc #SECONDS_IN_12H[15:8] ; Add to higher byte of 12 hours
  sta event_seconds + 1     ; Store in s1

  .done:
  plp                       ; Restore processor status
  rts                       ; Return from subroutine


; Synchronize to the closest second
time_sync:
  php                       ; Push processor status on the stack
  sei                       ; Do not allow interrupt

  lda event_ticks           ; Load current ticks
  cmp TICKS_PER_SEC / 2     ; Compare to half range
  bpl .round_down           ; Round down

  .round_up:
  wrb #99 event_ticks       ; Increment second at the next tick
  jmp .done                 ; We're done

  .round_down:
  wrb #0 event_ticks        ; Reset current second

  .done:
  plp                       ; Restore processor status
  rts                       ; Return from subroutine


; Return the current time as hour, minute and seconds
time_hours_minutes_seconds:
  wrw #0 hms_buffer + 0    ; Write 0 in a0
  wrw #0 hms_buffer + 2    ; Write 0 in a2
  wrw #0 hms_buffer + 4    ; Write 0 in a4

  php                      ; Push processor status on the stack
  sei                      ; Do not allow interrupt
  wrw event_seconds a0     ; Write seconds to a0
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
