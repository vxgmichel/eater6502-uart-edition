; Library for writing to the ROM


; Add _rom_write body to the program
#bank program

; Body of the _rom_write subroutine
_rom_write_start:
  ldx #0x40                ; Initializa X to 64
  ldy #0x00                ; Initialize Y to 0

  lda #0xaa                ; Program write mode by writing a magic sequence of values to specific addresses
  sta (0x5555 | 0x8000)    ; ... Then we have 150 us to write the first byte
  lda #0x55                ; ... Then 150 us to write the next byte
  sta (0x2AAA | 0x8000)    ; ... And so on until up to 64 bytes have been written
  lda #0xa0                ; ...
  sta (0x5555 | 0x8000)    ; ...

  .byte_loop:
  lda (a0), y              ; Load byte
  sta (a2), y              ; Write byte
  iny                      ; Increment Y
  dex                      ; Decrement X
  bne .byte_loop           ; Loop over bytes

  dey                      ; Decrement Y back to the last written value
  .wait_loop:              ; Loop until write is over
  lda (a2), y              ; Read ROM
  eor (a2), y              ; XOR with the last read
  bne .wait_loop           ; Wait until bit 6 stops toggling

  rts                      ; Jump back into rom_write
_rom_write_end:
_rom_write_length = _rom_write_end - _rom_write_start

; Reserve the correct size in RAM
#bank ram
rom_write_body:
#res _rom_write_length  ; Reserve 31 bytes


; Add rom_write function to the program
#bank program

; Read 64 bytes of ram from a0 and write to ROM at a2
rom_write:
  txa                     ; Transfer X to A
  pha                     ; And push it onto the stack
  tya                     ; Transfer Y to A
  pha                     ; And push it onto the stack

  php                     ; Push processor status on the stack
  sei                     ; Do not allow interrupt

  ldx #_rom_write_length  ; Load X with the copy length
  ldy #0x00               ; Load Y with 0

  .byte_loop:             ; Loop over bytes
  lda _rom_write_start, y ; Load byte from ROM
  sta rom_write_body, y   ; Write byte to RAM
  iny                     ; Increment Y
  dex                     ; Decrement X
  bne .byte_loop          ; Loop until last byte

  jsr rom_write_body      ; Jump to rom write body

  plp                     ; Restore processor status
  pla                     ; Pull Y from the stack
  tay                     ; And transfer it
  pla                     ; Pull Y from the stack
  tax                     ; And transfer it
  rts                     ; Return
