; A program generating random 8-bit integer,
; and printing them on the LCD display

#include "layouts/subeater.asm"


; Main program

#bank program
reset:

  ldx #0xff          ; Initialize the stack pointer at the end of its dedicated page
  txs

  jsr rng_init       ; Initialize the RNG
  jsr lcd_init       ; Initialize the LCD display
  jsr event_init     ; Initialize the event module

  .main:
  jsr lcd_clear      ; Clear the LCD display

  ldx #0             ; Initalize X register
  .print:
  lda message,x      ; Get a character from message, indexed by X
  beq .done          ; Start over when the zero char is reached
  jsr lcd_print_char ; Print the character
  inx                ; Increment the X register
  jmp .print         ; Loop over
  .done:

  jsr rng_step       ; Step the RNG
  lda rng_a          ; Get the current random value
  jsr lcd_print_num  ; Print it
  lda #100           ; Load 100 * 10 ms
  jsr event_sleep    ; Sleep for 1 second
  jmp .main          ; Loop over


; Static data

message:
#d "Random: "        ; This is the string to display
#d "\0"              ; Null terminated


; Interrupt handling

nmi:
  rti

irq:
  jsr event_irq
  rti


; Libraries

#include "libraries/lcd.asm"
#include "libraries/rng.asm"
#include "libraries/event.asm"

