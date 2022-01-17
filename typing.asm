; A program that receives data from the UART and shows it on the LCD display
; It supports backspace and newline

#include "layouts/subeater.asm"


; Main program
#bank program

reset:

  jsr lcd_init         ; Init LCD display
  jsr lcd_blink_on     ; Blinking cursor
  jsr uart_init        ; Configure UART

  .main:
  jsr uart_read_one    ; Read one byte from UART
  cmp #0x7f            ; Compare to DEL
  beq .del_char        ; Delete char handler
  cmp #"\r"            ; Compare to \r
  beq .new_line        ; New line handler

  .print_char:
  jsr lcd_print_char   ; Print character
  jmp .done            ; We're done

  .del_char:
  jsr lcd_del_char     ; Delete character
  jmp .done            ; We're done

  .new_line:
  jsr lcd_new_line     ; Go to next line
  jmp .done            ; We're done

  .done:
  jmp .main            ; Loop forever

; Interrupt

nmi:
irq:
  rti

; Libraries

#include "libraries/lcd.asm"
#include "libraries/uart.asm"
