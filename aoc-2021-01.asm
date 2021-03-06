; A subprogram that solve the first problem of the Advent of Code 2021:
; https://adventofcode.com/2021/day/1
; The intermediate results are both written to the LCD and the serial line.

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

  ; Write '0' to LCD display
  lda #"0"
  jsr lcd_print_char

  ; Init previous value in r2
  wrw #string_buffer a0
  jsr uart_readline
  jsr from_base10
  wrw a0 r2

  ; Loop over lines
  .line_loop:

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

  ; Read line to a0
  wrw #string_buffer a0
  jsr uart_readline
  jsr from_base10

  ; Compare previous and new value
  sec
  lda r2
  sbc a0
  lda r3
  sbc a1
  php

  ; Copy a0 to r2
  wrw a0 r2

  ; Done if not increasing
  plp
  bpl .done

  ; Increment result
  inw r0

  ; Loop over
  .done:
  jmp .line_loop


; Interrupt

nmi:
irq:
  rti

; Libraries

#include "libraries/lcd.asm"
#include "libraries/uart.asm"
#include "libraries/decimal.asm"
