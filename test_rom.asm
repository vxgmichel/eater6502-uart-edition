; Test script

#include "layouts/subeater.asm"


; Allocate a string buffer

#bank ram
string_buffer: #res 256


; Main program
#bank program

reset:

  jsr lcd_init          ; Init LCD
  jsr lcd_clear         ; Clear lCD
  jsr sleep             ; Wait for ROM safety to fade away
  wrw #0x0000 r0        ; Load 0 in word r0

  .main:                ; Main program

  wrw r0 a0             ; Copy value in word r0 to first argument
  wrw #string_buffer a2 ; Load string buffer as destination
  jsr to_base10         ; Convert to decimal

  wrw #string_buffer a0 ; Load string buffer address as source
  wrw #rom_data a2      ; Load rom data address as destination
  jsr rom_write         ; Write to rom

  jsr lcd_clear         ; Clear LCD
  jsr lcd_print_str     ; Print string buffer to LCD
  lda #":"              ; Load a separator
  jsr lcd_print_char    ; Print the separator

  wrw #rom_data a0      ; Load rom data address as argument
  jsr lcd_print_str     ; Print rom data
  lda #":"              ; Load a separator
  jsr lcd_print_char    ; Print the separator

  inw r0                ; Increment word in r0
  jmp .main             ; Loop over

; Interrupt

nmi:
irq:
  rti

; Libraries

#include "lib/lcd.asm"
#include "lib/rom.asm"
#include "lib/decimal.asm"

; Reserve data
#align 256 * 8  ; Next page
rom_data:       ; Reserve a page
#res 256
