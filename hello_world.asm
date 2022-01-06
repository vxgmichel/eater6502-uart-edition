; Simple program printing "Hello, World!" to the LCD display,
; waiting for a while between each character

#include "layouts/subeater.asm"


#bank program

; Main program

reset:
  ldx #0xff           ; Initialize the stack pointer at the end of its dedicated page
  txs

  jsr lcd_init        ; Initialize LCD display

  .main:
  jsr lcd_clear       ; Clear display

  ldx #0              ; Initalize X register
  .print:
  lda message,x       ; Get a character from message, indexed by X
  beq .done           ; Start over when the zero char is reached
  jsr lcd_print_char  ; Print the character
  jsr sleep           ; Sleep for a while
  inx                 ; Increment the X register
  jmp .print          ; Loop over

  .done:
  jsr sleep           ; Sleep for about 1 second
  jsr sleep
  jsr sleep
  jmp .main           ; Loop over

message:
#d "Hello, World!"  ; This is the string to display
#d "\0"                 ; Null terminated

; Interrupt handling

nmi:
irq:
  rti

; Libraries

#include "lib/lcd.asm"

