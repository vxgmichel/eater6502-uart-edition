; Simple program printing "Hello, World!" to the LCD display,
; waiting for a while between each character

#include "layouts/subeater.asm"


#bank program

; Main program

reset:
  ldx #0xff           ; Initialize the stack pointer at the end of its dedicated page
  txs

  jsr lcd_init        ; Initialize LCD display
  jsr time_init       ; Initialize time module

  .main:
  jsr lcd_clear       ; Clear display

  ldx #0              ; Initalize X register
  .print:
  lda message,x       ; Get a character from message, indexed by X
  beq .done           ; Start over when the zero char is reached
  jsr lcd_print_char  ; Print the character
  lda #20             ; Load 20 * 10 ms
  jsr time_sleep      ; Sleep for 0.2 seconds
  inx                 ; Increment the X register
  jmp .print          ; Loop over

  .done:
  lda #100            ; Load 100 * 10 ms
  jsr time_sleep      ; Sleep for 1 second
  jmp .main           ; Loop over

message:
#d "Hello, World!"    ; This is the string to display
#d "\0"               ; Null terminated

; Interrupt handling

nmi:
  rti

irq:
  jsr time_irq
  rti

; Libraries

#include "libraries/lcd.asm"
#include "libraries/time.asm"

