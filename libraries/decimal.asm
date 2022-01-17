; Library for decimal conversion
#once
#include "./math.asm"


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



; Convert a number to ascii string in base 10
; Arguments
; - A: minimal size
; - a0-a1: value to convert
; - a2-a3: buffer to write
; - a4-a5: end of buffer
to_base10_zero_padding:
  sta s0                  ; Store A in s0
  txa                     ; Push X
  pha                     ; Onto the stack
  tya                     ; Push Y
  pha                     ; Onto the stack

  lda r0                  ; Push r0
  pha                     ; Onto the stack
  lda r1                  ; Push r1
  pha                     ; Onto the stack
  lda r2                  ; Push r2
  pha                     ; Onto the stack

  wrb s0 r2               ; Save A argument to r2
  wrw a2 r0               ; Store a2 word to r0

  wrw #10 a2              ; Load 10 in a2 word
  wrw #division_buffer a4 ; Write division buffer to a4

  jsr successive_division ; Perform successive division
  wrw r0 a2               ; Restore a2 argument

  lda #0                  ; Load zero
  tax                     ; To X register

  lda a6                  ; Load buffer size
  lsr a                   ; Divide by 2
  sta s0                  ; Store in s0
  lda r2                  ; Load write length
  sec                     ; Prepare subtraction
  sbc s0                  ; Subtract buffer size
  tay                     ; Transfer to Y

  .padding_loop:
  beq .padding_end        ; Done with padding
  lda #"0"                ; Load zero char
  sta (r0, x)             ; Write to r0
  inw r0                  ; Increment r0
  dey                     ; Decrement Y
  jmp .padding_loop       ; Loop over
  .padding_end:

  lda a6                  ; Load result buffer size
  tay                     ; to Y register
  .char_loop:             ; Loop over buffer in reverse
  beq .char_end           ; Stop when when start of buffer is reached
  dey                     ; Decrement Y register
  dey                     ; Twice
  lda (a4), y             ; Get the corresponding character
  clc                     ; Prepare addition
  adc #"0"                ; Convert to character
  sta (r0, x)             ; Write to r0
  inw r0                  ; Increment r0
  tya                     ; Prepare Y for comparison
  jmp .char_loop          ; Loop over characters
  .char_end:

  wrw r0 a4               ; Write end of buffer to a4
  lda #"\0"               ; Write a null byte
  sta (a4)                ; at the end of the buffer

  pla                     ; Pull r2
  sta r2                  ; From the stack
  pla                     ; Pull r2
  sta r1                  ; From the stack
  pla                     ; Pull r2
  sta r0                  ; From the stack
  pla                     ; Pull Y
  tay                     ; From the stack
  pla                     ; Pull X
  tax                     ; From the stack
  rts                     ; Return from subroutine
