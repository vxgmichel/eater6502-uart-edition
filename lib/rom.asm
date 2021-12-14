; Library for writing to the ROM


; Add function rom_write to the program
#bank program

; Read 64 bytes of ram from a0 and write to ROM at a2
rom_write:
  txa                   ; Transfer X to A
  pha                   ; And push it onto the stack
  tya                   ; Transfer Y to A
  pha                   ; And push it onto the stack

  ldy #0x00             ; Initialize Y to 0
  ldx #0x40             ; Initialize X to 64

  lda #0xaa             ; Program write mode by writing a magic sequence of values to specific addresses
  sta (0x5555 | 0x8000) ; ... Then we have 150 us to write the first byte
  lda #0x55             ; ... Then 150 us to write the next byte
  sta (0x2AAA | 0x8000) ; ... And so on until up to 64 bytes have been written
  lda #0xa0             ; ...
  sta (0x5555 | 0x8000) ; ...

  .byte_loop:
  lda (a0), y           ; Load byte
  sta (a2), y           ; Write byte
  iny                   ; Increment Y
  dex                   ; Decrement X
  bne .byte_loop        ; Loop over bytes

  ldy #0x00             ; Clear Y
  .wait_loop:           ; Loop until write is over
  lda (a2), y           ; Read ROM
  eor (a2), y           ; XOR with the same read
  bne .wait_loop        ; Wait until bit 6 stops toggling

  pla                   ; Pull Y from the stack
  tay                   ; And transfer it
  pla                   ; Pull X from the stack
  tax                   ; And transfer it
  rts                   ; Return
