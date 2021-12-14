; Test script

#include "map/rameater.asm"


; Allocate a string buffer

#bank ram
string_buffer: #res 256


; Main program
#bank program

reset:
  ; Init LCD
  jsr lcd_init
  jsr lcd_clear

  ; Wait for ROM safety to fade away
  jsr sleep

  ; Load 0 in r0-r1
  lda #0x00
  sta r0
  sta r1

  .main:

  ; Load value a0-a1
  lda r0
  sta a0
  lda r1
  sta a1

  ; Load destination to a2-a3
  lda #string_buffer`8
  sta a2
  lda #(string_buffer >> 8)`8
  sta a3

  ; Convert to decimal
  jsr to_base10

  ; Load source
  lda #string_buffer`8
  sta a0
  lda #(string_buffer >> 8)`8
  sta a1

  ; Write to rom
  lda #0x00
  sta a2
  lda #0x90
  sta a3
  jsr rom_write

  ; Print result from ram
  jsr lcd_clear
  jsr lcd_print_str
  lda #":"
  jsr lcd_print_char

  ; Copy string buffer argument
  lda a2
  sta a0
  lda a3
  sta a1

  ; Print result from rom
  jsr lcd_print_str
  lda #":"
  jsr lcd_print_char

  ; Increment r0-r1
  inc r0
  bne .skip
  inc r1
  .skip:

  ; Loop over
  jmp .main

; Interrupt

nmi:
irq:
  rti

; Libraries

#include "lib/lcd.asm"
#include "lib/rom.asm"
#include "lib/decimal.asm"