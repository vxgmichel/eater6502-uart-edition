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
  tya            ; Push Y
  pha            ; Onto the stack

  ldy #0         ; Set Y to zero
  wrw #0 s0      ; Set s0 word to zero
  wrw #0 s2      ; Set s1 word to zero
  wrb #0 s4      ; Set s4 to zero

  .char_loop:    ; Loop over characters
  lda (a0), y    ; Get character
  sec            ; Prepare subtraction
  sbc #"0"       ; Convert to integer
  bmi .done      ; Not a digit, we're done
  sta s4         ; Store integer in s4

  asl s0         ; Double s0 word
  rol s1         ; Propagate carry

  wrw s0 s2      ; Copy s0 word to s2

  asl s0         ; Double s0 word
  rol s1         ; Propagate carry

  asl s0         ; Double s0 word
  rol s1         ; Propagate carry

  clc            ; Prepare addition
  lda s0         ; Add s2 word to s0
  adc s2         ; Effectively multiplying by 10
  sta s0         ; ...
  lda s1         ; ...
  adc s3         ; ...
  sta s1         ; ...

  clc            ; Prepare addition
  lda s0         ; Add new digit
  adc s4         ; and propagate carry
  sta s0         ; ...
  lda s1         ; ...
  adc #0         ; ...
  sta s1         ; ...

  iny            ; Increment Y
  jmp .char_loop ; Loop over

  .done:
  wrw s0 a0      ; Write s0 word to a0
  pla            ; Pull Y
  tay            ; From the stack
  rts            ; Return from subroutine


; Convert a number to ascii string in base 10
; Arguments
; - a0-a1: value to convert
; - a2-a3: buffer to write
; - a4-a5: end of buffer
to_base10:
  pha                        ; Save A on the stack
  lda #1                     ; Zero-pagging of length 1
  jsr to_base10_zero_padding ; Call conversion routine
  pla                        ; Restore A register
  rts                        ; Return from subroutine


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
  bmi .padding_end        ; No padding if negative

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
  sta (a4, x)             ; at the end of the buffer

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
