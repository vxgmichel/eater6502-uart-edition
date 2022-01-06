; Library for decimal conversion

; Allocate a buffer for division in the ram
#bank ram
division_buffer: #res 2 * 16


; Add functions to the program
#bank program

; Parse the null-terminated string provided at address (a0-a1)
; And return the corresponding value in a0-a1
from_base10:
  tya
  pha
  lda r0
  pha

  ldy #0x00
  lda #0x00
  sta s0
  sta s1
  sta s2
  sta s3
  sta r0

  .char_loop:
  lda (a0), y
  sec
  sbc #"0"
  bmi .done
  sta r0

  clc
  asl s0 ; Double s0-s1
  rol s1 ; ...

  lda s0 ; Copy to s2-s3
  sta s2 ; ...
  lda s1 ; ...
  sta s3 ; ...

  asl s0 ; Double s0-s1
  rol s1 ; ...

  asl s0 ; Double s0-s1
  rol s1 ; ...

  lda s0 ; Add s2-s3 to s0-s1
  adc s2 ; Effectively multiplying by 10
  sta s0
  lda s1
  adc s3
  sta s1

  lda s0 ; Add new digit
  adc r0 ; and propagate carry
  sta s0
  lda s1
  adc #0x00
  sta s1

  iny
  jmp .char_loop

  .done:
  lda s0 ; Copy s0-s1 to a0-a1
  sta a0 ; ...
  lda s1 ; ...
  sta a1 ; ...

  pla
  sta r0
  pla
  tay
  rts


; Convert a number to ascii string in base 10
; Arguments
; - a0-a1: value to convert
; - a2-a3: buffer to write
; - a4-a5: end of buffer
to_base10:
  txa           ; Push X-Y on the stack
  pha
  tya
  pha

  lda r0        ; Push r0-r1 onto the stack
  pha
  lda r1
  pha

  lda a2        ; Store a2-a3 to r0-r1
  sta r0
  lda a3
  sta r1

  lda #0x0a                   ; Load 10 in a2-a3
  sta a2
  lda #0x00
  sta a3

  lda #division_buffer`8      ; Load division buffer to a4-a5
  sta a4
  lda #(division_buffer>>8)`8
  sta a5

  jsr successive_division     ; Perform successive division


  ldx #0x00                   ; Loop over characters
  lda a6                      ; Load result buffer size to Y
  tay
  .char_loop:
  beq .done                   ; Loop over division buffer in reverse
  dey                         ; Stop when when start of buffer is reached
  dey

  lda (a4), y                 ; Get the corresponding character
  clc
  adc #"0"
  sta s1

  txa                         ; Swap X-Y
  sta s0
  tya
  tax
  lda s0
  tay

  lda s1
  sta (r0), y                 ; Write to output buffer
  iny

  txa                         ; Swap X-Y
  sta s0
  tya
  tax
  lda s0
  tay

  jmp .char_loop              ; Loop over characters

  .done:

  txa                         ; Transfer X to s0
  sta s0

  bne .skip                   ; Add a "0" if necessary
  tay
  lda #"0"
  sta (r0), y
  inc s0
  .skip:

  clc                         ; Copy buffer start to a2-a3
  lda r0                      ; and buffer stop to a4-a5
  sta a2
  adc s0
  sta a4
  lda r1
  sta a3
  adc #0
  sta a5

  ldy #0x00                   ; Write a null byte at the end
  lda #"\0"
  sta (a4), y

  pla                         ; Pull r0-r1 from the stack
  sta r1
  pla
  sta r0

  pla                         ; Pull X and Y from the stack
  tay
  pla
  tax

  rts                         ; Return


; Divide the dividend by the provided divisor
; Arguments
; - a0-a1: dividend
; - a2-a3: divisor
; - a4-a5: result buffer
; Results:
; - a6: buffer size
successive_division:
  txa                  ; Push context on the stack
  pha
  tya
  pha

  lda a0               ; Copy arguments to scratch
  sta s0
  lda a1
  sta s1

  ldy #0x00            ; Loop over remainders indexed by Y
  .remainder_loop:

  lda s0               ; If dividend is zero, we're done
  ora s1
  beq .done

  lda #0x00            ; Initialize remainder
  sta s2
  sta s3

  clc                  ; Clear carry as we plan to rotate
  ldx #0x10            ; Loop over 16 shifts
  .shift_loop:

  rol s0               ; Rotate all 4 bytes
  rol s1
  rol s2
  rol s3

  sec                  ; Subtract divisor
  lda s2
  sbc a2
  sta s4
  lda s3
  sbc a3

  bcc .skip            ; If result is strictly negative, skip
  sta s3               ; If result is positive or zero, write back
  lda s4
  sta s2
  .skip:

  dex                  ; Loop over the shifts
  bne .shift_loop      ; Until we're done

  rol s0               ; Perform last rotation
  rol s1

  lda s2               ; Copy the remainder in the buffer
  sta (a4), y
  iny
  lda s3
  sta (a4), y
  iny

  jmp .remainder_loop  ; Loop to the next remainder operation

  .done:

  tya                  ; Transfer buffer size to a6
  sta a6

  pla                  ; Pull the context from the stack and return
  tay
  pla
  tax
  rts




