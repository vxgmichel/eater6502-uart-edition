; Test script

#include "map/subeater.asm"


; Allocate a string buffer

#bank ram
string_buffer: #res 256


; Main program
#bank program

reset:
  ; Init LCD
  jsr lcd_init
  jsr lcd_clear

  ;jsr sleep
  ;jsr sleep
  ;jsr sleep

  ; Configure UART
  jsr uart_init

  ; Load value1_str to a0-a1
  lda #value1_str`8
  sta a0
  lda #(value1_str >> 8)`8
  sta a1

  ; Convert to base10 and move to r0-r1
  jsr from_base10
  lda a0
  sta r0
  lda a1
  sta r1

  ; Load value2_str to a0-a1
  lda #value2_str`8
  sta a0
  lda #(value2_str >> 8)`8
  sta a1

  ; Convert to base10 and move to r2-r3
  jsr from_base10
  lda a0
  sta r2
  lda a1
  sta r3

  ; Add both numbers and write to a0-a1
  clc
  lda r0
  adc r2
  sta a0
  lda r1
  adc r3
  sta a1

  ; Prepare string buffer argument
  lda #string_buffer`8
  sta a2
  lda #(string_buffer >> 8)`8
  sta a3

  ; Convert result to base 10
  jsr to_base10

  ; Copy string buffer argument
  lda a2
  sta a0
  lda a3
  sta a1

  ; Print number
  jsr lcd_print_str

  jsr sleep
  jsr sleep
  jsr sleep

  ; Write to serial
  ldy #0x00

  lda (a0), y
  sta UART_THR
  iny
  jsr sleep
  jsr sleep
  jsr sleep

  lda (a0), y
  sta UART_THR
  iny
  jsr sleep
  jsr sleep
  jsr sleep

  lda (a0), y
  sta UART_THR
  iny
  jsr sleep
  jsr sleep
  jsr sleep

  lda (a0), y
  sta UART_THR
  iny
  jsr sleep
  jsr sleep
  jsr sleep

  lda #"!"
  jsr lcd_print_char

  ; Loop forever
  .done:
  jmp .done

; Data

value1_str:
#d "00000"
#d "\0"

value2_str:
#d "12345"
#d "\0"

; Interrupt

nmi:
irq:
  rti

; Libraries

#include "lib/lcd.asm"
#include "lib/uart.asm"
#include "lib/decimal.asm"