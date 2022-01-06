; Test script

#include "layouts/subeater.asm"


; Allocate a string buffer

#bank ram
string_buffer: #res 256


; Main program
#bank program

reset:
  ; Init LCD
  jsr lcd_init

  ; Configure UART
  jsr uart_init

  ; Init accumulator in r0
  wrw #0 r0

  ; Write 0 to LCD display
  jsr lcd_clear
  lda #"0"
  jsr lcd_print_char

  ; Loop over lines
  .line_loop:

  ; Read line to a0
  wrw #string_buffer a0
  jsr uart_readline

  ; Convert to base10
  jsr from_base10

  ; Add to accumulator
  clc
  lda a0
  adc r0
  sta r0
  lda a1
  adc r1
  sta r1

  ; Convert result to base 10
  wrw r0 a0
  wrw #string_buffer a2
  jsr to_base10

  ; Print result
  jsr lcd_clear
  wrw a2 a0
  jsr lcd_print_str

  ; Write to serial
  jsr uart_writeline

  ; Loop over
  jmp .line_loop


; Interrupt

nmi:
irq:
  rti

; Libraries

#include "libraries/lcd.asm"
#include "libraries/uart.asm"
#include "libraries/decimal.asm"