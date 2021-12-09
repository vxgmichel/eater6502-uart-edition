; Program showing the content of the UART register on the LCD display

#include "map/subeater.asm"


; Main program

#bank program
reset:

  ldx #0xff            ; Initialize the stack pointer at the end of its dedicated page
  txs
  jsr uart_init        ; Initialize the UART receiver/transmitter
  jsr lcd_init         ; Initialize the LCD display

  ; Main loop
  .main:

  jsr lcd_clear        ; Clear the LCD screen

  txa                  ; Increment the scratch register
  sta UART_SCR
  inx

  lda UART_RBR
  jsr lcd_print_num
  lda #"|"
  jsr lcd_print_char

  lda UART_IER
  jsr lcd_print_num
  lda #"|"
  jsr lcd_print_char

  lda UART_IIR
  jsr lcd_print_num
  lda #"|"
  jsr lcd_print_char

  lda UART_LCR
  jsr lcd_print_num
  lda #(0x40 | 0b10000000)
  jsr lcd_instruction

  lda UART_MCR
  jsr lcd_print_num
  lda #"|"
  jsr lcd_print_char

  lda UART_LSR
  jsr lcd_print_num
  lda #"|"
  jsr lcd_print_char

  lda UART_MSR
  jsr lcd_print_num
  lda #"|"
  jsr lcd_print_char

  lda UART_SCR
  jsr lcd_print_num

  .print_done:
  jsr sleep           ; Sleep about 1/3 seconds
  jmp .main           ; Loop over


; Interrupt handling

nmi:
irq:
  rti


; Libraries

#include "lib/lcd.asm"
#include "lib/uart.asm"