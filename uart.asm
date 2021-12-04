#include "cpu6502.asm"
#include "eater.asm"

#bank zeropage
scratch:
s0: #res 1
s1: #res 1
s2: #res 1
s3: #res 1
registers:
r0: #res 1
r1: #res 1
r2: #res 1
r3: #res 1
rng:
rng_x: #res 1
rng_y: #res 1
rng_z: #res 1
rng_a: #res 1
rng_t: #res 1


#bank program

; Main program

reset:
  ; Initialize the stack pointer at the end of its dedicated page
  ldx #0xff
  txs

  ; Initialize the RNG seed for a cycle of length 4261412737
  lda #0x01
  sta rng_x
  sta rng_y
  sta rng_z
  sta rng_a

  ; Configure UART receiver
  jsr configure_uart

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

  ; Main loop
  .main:

  ; Clear display
  lda #0b00000001
  jsr lcd_instruction

  ; Return home
  lda #0b00000010
  jsr lcd_instruction

  ; Write message
  txa
  sta UART_SCR
  inx

  lda UART_RBR
  jsr print_num
  lda #"|"
  jsr print_char

  lda UART_IER
  jsr print_num
  lda #"|"
  jsr print_char

  lda UART_IIR
  jsr print_num
  lda #"|"
  jsr print_char

  lda UART_LCR
  jsr print_num
  lda #(0x40 | 0b10000000)
  jsr lcd_instruction

  lda UART_MCR
  jsr print_num
  lda #"|"
  jsr print_char

  lda UART_LSR
  jsr print_num
  lda #"|"
  jsr print_char

  lda UART_MSR
  jsr print_num
  lda #"|"
  jsr print_char

  lda UART_SCR
  jsr print_num

  .print_done:
  jsr sleep      ; Sleep about 1/3 seconds
  jmp .main      ; Loop over

; Subroutines

; Configure the UART receiver
; Line control configuration:
; - Baud rate: 4807 Hz (1MHz / 16 / 13)
; - 8-bit characters
; - 2 stop bits
; - Enable even parity
; - No stick bit
; - No break
; Modem control configuration:
; - Enable auto RTS/CTS
; FIFO configuration:
; - Enable FIFO
; - Reset FIFO
; - Set trigger level to 1
configure_uart:
  pha             ; Push A onto the stack

  lda #LCR_DIVLTC  ; Set the divisor latch
  sta UART_LCR     ; Write to LCR

  lda #0x0d       ; Set the divisor lower byte (13)
  sta UART_DLL    ; Write to DLL
  lda #0x00       ; Set the divisor higher byte (0)
  sta UART_DLM    ; Write to DLM

  lda #LCR_CONFIG ; Configure line control
  sta UART_LCR    ; Write to LCR

  lda #FCR_CONFIG ; Configure FIFO control
  sta UART_FCR    ; Write to FCR

  lda UART_MCR    ; Load MCR
  ora #MCR_AUTRTS ; Enable auto RTS/CTS
  sta UART_MCR    ; Write MCR

  pla             ; Pull A from the stack
  rts             ; Return

rng_step:
  pha             ; Push A onto the stack

  lda rng_x       ; Compute new t value
  asl a           ; By shifting x left
  asl a           ; 4 times
  asl a           ; ...
  asl a           ; ...
  eor rng_x       ; XOR with itself
  sta rng_t       ; And store in t

  lda rng_y       ; Copy Y
  sta rng_x       ; to X

  lda rng_z       ; Copy Z
  sta rng_y       ; to Y

  lda rng_a       ; Copy A
  sta rng_z       ; to Z

  lda rng_t       ; Compute new a value by loading t
  asl a           ; Shift it left
  eor rng_t       ; XOR with itself
  eor rng_z       ; Xor with z
  sta rng_a       ; Store in a

  lda rng_z       ; Load z
  lsr a           ; Sift it right
  eor rng_a       ; XOR with a
  sta rng_a       ; Store in a

  pla             ; Pull A from the stack
  rts             ; Return from subroutine

print_num:
  sta s0          ; Save argument in s0
  txa             ; Transfer X to A
  pha             ; Push X onto the stack
  lda s0          ; Restore argument in s0
  lsr a           ; Shift 4 times
  lsr a           ; to keep the 4 higher bits
  lsr a           ; ...
  lsr a           ; ...
  tax             ; Transfer A to X
  lda hexa, x     ; Load hexa value corresponding to X
  jsr print_char  ; Call print_char
  lda s0          ; Restore original argument
  and #0b00001111 ; Keep lower 4 bits
  tax             ; Transfer A to X
  lda hexa, x     ; Load hexa value corresponding to X
  jsr print_char  ; Call print_char
  pla             ; Pull original X from stack
  tax             ; Restore original X
  lda s0          ; Restore argument in s0
  rts             ; Return from subroutine


hexa:
#d "0123456789abcdef"

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
