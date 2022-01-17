; Library for generating randomness
#once


; Allocate globals for the RNG
#bank ram
rng:
rng_x: #res 1
rng_y: #res 1
rng_z: #res 1
rng_a: #res 1
rng_t: #res 1


; Add function rng_step to the program
#bank program

; Initialize the RNG seed for a cycle of length 4261412737
rng_init:
  lda #0x01
  sta rng_x
  sta rng_y
  sta rng_z
  sta rng_a
  rts

; Step the rng seed
rng_step:
  pha             ; Push A onto the stack

  lda rng_x       ; Compute new t value
  asl a           ; By shifting x left
  asl a           ; 4 times
  asl a           ; ...
  asl a           ; ...
  eor rng_x       ; XOR with itself
  sta rng_t       ; And store in t

  lda rng_y       ; Copy Y
  sta rng_x       ; to X

  lda rng_z       ; Copy Z
  sta rng_y       ; to Y

  lda rng_a       ; Copy A
  sta rng_z       ; to Z

  lda rng_t       ; Compute new a value by loading t
  asl a           ; Shift it left
  eor rng_t       ; XOR with itself
  eor rng_z       ; Xor with z
  sta rng_a       ; Store in a

  lda rng_z       ; Load z
  lsr a           ; Sift it right
  eor rng_a       ; XOR with a
  sta rng_a       ; Store in a

  pla             ; Pull A from the stack
  rts             ; Return from subroutine
