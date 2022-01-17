; Library for maths helpers
#once


; Add functions to the program
#bank program


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




