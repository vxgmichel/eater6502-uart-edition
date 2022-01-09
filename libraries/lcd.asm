; Library for controlling the LCD


; LCD constants

LCD_E  = 0b10000000 ; Pin Enable
LCD_RW = 0b01000000 ; Pin Read/Write
LCD_RS = 0b00100000 ; Pin Register select

LCD_I = 0x00   ; Instruction
LCD_D = LCD_RS ; Data

LCD_W = 0x00   ; Write
LCD_R = LCD_RW ; Read

LCD_RI = LCD_R | LCD_I ; Read instruction
LCD_WI = LCD_W | LCD_I ; Write instruction
LCD_RD = LCD_R | LCD_D ; Read data
LCD_WD = LCD_W | LCD_D ; Write data

LCD_RIE = LCD_RI | LCD_E ; Read instruction enable
LCD_WIE = LCD_WI | LCD_E ; Write instruction enable
LCD_RDE = LCD_RD | LCD_E ; Read data enable
LCD_WDE = LCD_WD | LCD_E ; Write data enable


; LCD functions

#bank program

lcd_init:
  lda #0b11100001          ; Configure first bit and last 3 bits of A to output
  sta DDRA                 ; ...
  lda #0b11111111          ; Configure port B to output
  sta DDRB                 ; ...
  lda #0b00111000          ; Set 8-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction      ; ...
  lda #0b00001100          ; Display on; cursor off; blink off
  jsr lcd_instruction      ; ...
  lda #0b00000110          ; Increment and shift cursor; don't shift display
  jsr lcd_instruction      ; ...
  rts

lcd_print_num:
  sta s0              ; Save argument in s0
  txa                 ; Transfer X to A
  pha                 ; Push X onto the stack
  lda r0              ; Load r0
  pha                 ; And push onto the stack
  lda s0              ; Restore argument in s0
  sta r0              ; And store to r0
  lsr a               ; Shift 4 times
  lsr a               ; to keep the 4 higher bits
  lsr a               ; ...
  lsr a               ; ...
  tax                 ; Transfer A to X
  lda hexa_symbols, x ; Load hexa value corresponding to X
  jsr lcd_print_char  ; Call print_char
  lda r0              ; Restore original argument
  and #0b00001111     ; Keep lower 4 bits
  tax                 ; Transfer A to X
  lda hexa_symbols, x ; Load hexa value corresponding to X
  jsr lcd_print_char  ; Call print_char
  lda r0              ; Load r0
  sta s0              ; And store to s0
  pla                 ; Pull r0 from the stack
  sta r0              ; And restore
  pla                 ; Pull original X from stack
  tax                 ; Restore original X
  lda s0              ; Restore argument in s0
  rts                 ; Return from subroutine


hexa_symbols:
#d "0123456789abcdef"

; Sleep for a while

sleep:
  txa             ; Transfer X to A
  pha             ; And push it onto the stack
  tya             ; Transfer Y to A
  pha             ; And push it onto the stack

  ldy #0xff       ; Initialize Y to 255
  .loop1:         ; Outer loop
  ldx #0xff       ; Initialize X to 255
  .loop2:         ; Inner loop
  dex             ; Decrement X
  bne .loop2      ; Jump to inner loop while X is not zero
  dey             ; Decrement Y
  bne .loop1      ; Jump to outer loop while Y is not zero

  pla             ; Pull Y from the stack
  tay             ; And transfer it
  pla             ; Pull X from the stack
  tax             ; And transfer it
  rts             ; Return


; Wait for the LCD display to be ready, preserving the accumulator
lcd_wait:
  pha             ; Push the accumulator onto the stack
  jsr lcd_tell    ; Wait for the LCD display to be ready
  pla             ; Restore the accumulator
  rts             ; Return from subroutine


; Wait for the LCD display to be ready, and return the cursor position
lcd_tell:
  lda #0b00000000 ; Set port B to input
  sta DDRB        ; Using the DDRB command

  .lcdbusy:       ; Loop waiting for the LCD to be idle
  lda #LCD_RI     ; Configure LCD read instruction
  sta PORTA       ; Using the port A
  lda #LCD_RIE    ; Enable LCD read instruction
  sta PORTA       ; Using the port A
  lda PORTB       ; Read port B to the accumulator
  sta s0          ; Store in s0
  and #0b10000000 ; Keep the MSB
  bne .lcdbusy    ; Loop if the value is not zero

  lda #LCD_RI     ; Clear LCD enable
  sta PORTA       ; Using port A
  lda #0b11111111 ; Configure B back to output
  sta DDRB        ; Using the DDRB command
  lda s0          ; Load cursor position in the accumulator
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
lcd_print_char:
  jsr lcd_wait    ; Wait for the display to be ready
  sta s0          ; Save argument to s0
  sta PORTB       ; Write the argument to port B
  lda #LCD_WD     ; Configure LCD write data
  sta PORTA       ; Using port A
  lda #LCD_WDE    ; Enable LCD write data
  sta PORTA       ; Using port A
  lda #LCD_WD     ; Clear LCD enable
  sta PORTA       ; Using port A
  lda s0          ; Restore argument
  rts             ; Return from subroutine


; Clear display and return home
lcd_clear:
  lda #0b00000001       ; Clear display
  jsr lcd_instruction   ; Write instruction

  lda #0b00000010       ; Return home
  jsr lcd_instruction   ; Write instruction

  rts                   ; Return from subroutine


; Print the string with address in a0 to LCD
lcd_print_str:
  tya                   ; Transfer Y to A
  pha                   ; And push it onto the stack

  ldy #0                ; Initalize Y register
  .char_loop:           ; Loop over characters

  lda (a0), y           ; Get a character from message, indexed by Y
  beq .done             ; Done with the printing
  jsr lcd_print_char    ; Print the character
  iny                   ; Increment Y
  jmp .char_loop        ; Loop over

  .done:                ; Done with the printing
  pla                   ; Pull Y from the stack
  tay                   ; And transfer it
  rts                   ; Return


; Delete a character from the LCD display
lcd_del_char:
  jsr lcd_wait        ; Get cursor position (once the display is ready)

  lda #0b00010000     ; Prepare command
  jsr lcd_instruction ; Move curor to the left

  lda #" "            ; Load a space
  jsr lcd_print_char  ; Print space

  lda #0b00010000     ; Prepare command
  jsr lcd_instruction ; Move cursor to the left

  rts                 ; Return from subroutine


; Go to next line on the LCD
lcd_new_line:
  jsr lcd_tell
  and #0b01000000
  eor #0b11000000
  jsr lcd_instruction      ; Write instruction
  rts
