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
  inc event_halfdays        ; Increment halfday counter

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
  dec event_halfdays        ; Decrement halfday counter

  .done:
  plp                       ; Restore processor status
  rts                       ; Return from subroutine


; Synchronize to the closest second
time_sync:
  php                              ; Push processor status on the stack
  sei                              ; Do not allow interrupt

  lda event_ticks                  ; Load current ticks
  cmp #TICKS_PER_SEC/2             ; Compare to half range
  bmi .round_down                  ; Round down

  .round_up:
  wrb #TICKS_PER_SEC-1 event_ticks ; Increment second at the next tick
  jmp .done                        ; We're done

  .round_down:
  wrb #0 event_ticks               ; Reset current second

  .done:
  plp                              ; Restore processor status
  rts                              ; Return from subroutine


; Return the current time as hour, minute and seconds
time_hours_minutes_seconds:
  lda r0                   ; Push r0
  pha                      ; Onto the stack

  wrw #0 hms_buffer + 0    ; Write 0 in a0
  wrw #0 hms_buffer + 2    ; Write 0 in a2
  wrw #0 hms_buffer + 4    ; Write 0 in a4

  php                      ; Push processor status on the stack
  sei                      ; Do not allow interrupt
  wrw event_seconds a0     ; Write seconds to a0
  wrb event_halfdays r0    ; Write halfdays to r0
  plp                      ; Restore processor status

  wrw #60 a2               ; Write divisor to a2
  wrw #hms_buffer a4       ; Write hms buffer address to a2
  jsr successive_division  ; Perform divisions

  wrw hms_buffer + 0 a4    ; Write seconds in a4
  wrw hms_buffer + 2 a2    ; Write minutes in a2
  wrw hms_buffer + 4 a0    ; Write hours in a0

  lda event_halfdays       ; Load half days
  lsr a                    ; Shift left
  bcc .halfday_done        ; Done if carry clear
  clc                      ; Prepare addition
  lda a0                   ; Load a0
  adc #12                  ; Add 12
  sta a0                   ; Write back
  .halfday_done:

  pla                      ; Pull r0
  sta r0                   ; From the stack
  rts                      ; Return from subroutine


; Convert hour-minute-second time to string
time_hms_to_str:
  lda r0                        ; Push r0
  pha                           ; Onto the stack
  lda r1                        ; Push r1
  pha                           ; Onto the stack
  lda r2                        ; Push r2
  pha                           ; Onto the stack
  lda r3                        ; Push r3
  pha                           ; Onto the stack

  wrw a2 r0                     ; Write minutes word to r0
  wrw a4 r2                     ; Write seconds word to r2

  wrw #hms_string a2            ; Write string address to a2
  lda #2                        ; Pad 2 characters with zeros
  jsr to_base10_zero_padding    ; Convert hours to base 10

  wrb #":" hms_string + 2       ; Write a column

  wrw r0 a0                     ; Write minutes word to a0
  wrw #(hms_string + 3) a2      ; Write string address with offset to a2
  lda #2                        ; Pad 2 characters with zeros
  jsr to_base10_zero_padding    ; Convert minutes to base 10

  wrb #":" hms_string + 5       ; Write a column

  wrw r2 a0                     ; Write seconds word to a0
  wrw #(hms_string + 6) a2      ; Write string address with offset to a2
  lda #2                        ; Pad 2 characters with zeros
  jsr to_base10_zero_padding    ; Convert seconds to base 10

  wrb #"\0" hms_string + 8      ; Write null byte at the end of the string
  wrw #hms_string a0            ; Write buffer address to a0

  pla                           ; Pull r3
  sta r3                        ; From the stack
  pla                           ; Pull r2
  sta r2                        ; From the stack
  pla                           ; Pull r1
  sta r1                        ; From the stack
  pla                           ; Pull r0
  sta r0                        ; From the stack
  rts                           ; Return from subroutine


; Return the current 24-hour time as a string address in a0 word
time_24_hour_str:
  jsr time_hours_minutes_seconds ; Get current time
  jsr time_hms_to_str            ; Convert to string
  rts                            ; Return from subroutine


; Return the current 12-hour time as two string addresses in a0 and a1 words
time_12_hour_str:
  jsr time_hours_minutes_seconds ; Get current time

  sec                            ; Prepare substraction
  lda a0                         ; Load hours
  sbc #12                        ; Subtract 12
  php                            ; Push status for later use

  bmi .skip1                     ; Test AM/PM
  sta a0                         ; Write back if positive or zero
  .skip1:

  lda a0                         ; Load hours
  bne .skip2                     ; Skip if not zero
  lda #12                        ; Replace zero hours
  sta a0                         ; With 12 hours
  .skip2:

  jsr time_hms_to_str            ; Convert to string

  plp                            ; Get previous comparison status
  bpl .pm                        ; Test AM/PM
  .am:
  wrw #AM_STRING a2              ; Load AM string
  jmp .done                      ; We're done
  .pm:
  wrw #PM_STRING a2              ; Load PM string
  .done:

  rts                            ; Return from subroutine


; AM/PM strings

AM_STRING: #d "AM\0"
PM_STRING: #d "PM\0"
