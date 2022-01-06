; A program that receives data from the UART and shows it on the LCD display
; It supports backspace and newline

#include "layouts/subeater.asm"


; Main program
#bank program

reset:
  ; Init LCD
  jsr lcd_init
  jsr lcd_clear

  ; Blinking cursor
  lda #0b00001101
  jsr lcd_instruction

  ; Configure UART
  jsr uart_init

  .main:
  jsr uart_read_one
  cmp #0x7f
  beq .del_char
  cmp #"\n"
  beq .new_line
  .print_char:
  jsr lcd_print_char
  jmp .done
  .del_char:
  jsr lcd_del_char
  jmp .done
  .new_line:
  jsr lcd_new_line
  jmp .done

  ; Loop forever
  .done:
  jmp .main

; Interrupt

nmi:
irq:
  rti

; Libraries

#include "libraries/lcd.asm"
#include "libraries/uart.asm"