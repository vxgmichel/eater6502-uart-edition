#include "cpu6502.asm"
#include "eater.asm"


#bank program

; Main program

reset:
  ; Initialize the stack pointer at the end of its dedicated page
  ldx #0xff
  txs

  ; Configure last 3 bits of A to output
  lda #0b11100000
  sta DDRA

  ; Configure port B to output
  lda #0b11111111
  sta DDRB

  ; Set 8-bit mode; 2-line display; 5x8 font
  lda #0b00111000
  jsr lcd_instruction

  ; Display on; cursor off; blink off
  lda #0b00001100
  jsr lcd_instruction

  ; Increment and shift cursor; don't shift display
  lda #0b00000110
  jsr lcd_instruction

main:
  ; Clear display
  lda #0b00000001
  jsr lcd_instruction

  ; Return home
  lda #0b00000010
  jsr lcd_instruction

  ldx #0          ; Initalize X register
print:
  lda message,x   ; Get a character from message, indexed by X
  beq done        ; Start over when the zero char is reached
  jsr print_char  ; Print the character
  jsr sleep       ; Sleep for a while
  inx             ; Increment the X register
  jmp print       ; Loop over

done:
  jsr sleep
  jsr sleep
  jsr sleep
  jmp main       ; Loop over

message:
#d "Hello, world!"  ; This is the string to display
#d "\0"                 ; Null terminated

; Subroutines

; Sleep for a while
sleep:
  txa             ; Transfer X to A
  pha             ; And push it onto the stack

  ldy #0xff       ; Initialize Y to 255
loop1:            ; Outer loop
  ldx #0xff       ; Initialize X to 255
loop2:            ; Inner loop
  dex             ; Decrement X
  bne loop2       ; Jump to inner loop while X is not zero
  dey             ; Decrement Y
  bne loop1       ; Jump to outer loop while Y is not zero

  pla             ; Pull A from the stack
  tax             ; And transfer it to X
  rts             ; Return from subroutine


; Wait for the LCD display to be ready, preserving the accumulator
lcd_wait:
  pha             ; Push the accumulator onto the stack
  lda #0b00000000 ; Set port B to input
  sta DDRB        ; Using the DDRB command

lcdbusy:          ; Loop waiting for the LCD to be idle
  lda #LCD_RI     ; Configure LCD read instruction
  sta PORTA       ; Using the port A
  lda #LCD_RIE    ; Enable LCD read instruction
  sta PORTA       ; Using the port A
  lda PORTB       ; Read port B to the accumulator
  and #0b10000000 ; Keep the MSB
  bne lcdbusy     ; Loop if the value is not zero

  lda #LCD_RI     ; Clear LCD enable
  sta PORTA       ; Using port A
  lda #0b11111111 ; Configure B back to output
  sta DDRB        ; Using the DDRB command
  pla             ; Pull the accumulator from the stack
  rts             ; Return from the subroutine


; Writes the instruction in the accumulator to the LCD display
lcd_instruction:
  jsr lcd_wait   ; Wait for the display to be ready
  sta PORTB      ; Write argument to port B
  lda #LCD_WI    ; Configure LCD write instruction
  sta PORTA      ; Using port A
  lda #LCD_WIE   ; Enable LCD write instruction
  sta PORTA      ; Using port A
  lda #LCD_WI    ; Clear LCD enable
  sta PORTA      ; Using port A
  rts            ; Return from subroutine

; Print the character in the accumulator to the LCD display
print_char:
  jsr lcd_wait    ; Wait for the display to be ready
  sta PORTB       ; Write the argument to port B
  lda #LCD_WD     ; Configure LCD write data
  sta PORTA       ; Using port A
  lda #LCD_WDE    ; Enable LCD write data
  sta PORTA       ; Using port A
  lda #LCD_WD     ; Clear LCD enable
  sta PORTA       ; Using port A
  rts             ; Return from subroutine

; Interrupt handling

nmi:
irq:
  rti

