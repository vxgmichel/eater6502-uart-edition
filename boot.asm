#include "cpu6502.asm"
#include "rameater.asm"

#bank zeropage
scratch:
s0: #res 1
s1: #res 1
s2: #res 1
s3: #res 1
arguments:
a0: #res 1
a1: #res 1
a2: #res 1
a3: #res 1
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

#bank ram
serial_buffer: #res 0x40


#bank program

; Main program

reset:

  ; Configuration

  ldx #0xff                ; Initialize the stack pointer at the end of its dedicated page
  txs                      ; ...

  jsr configure_uart       ; Configure UART receiver

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

  ; Main program
  lda PORTA                ; Load port A
  and #0b00000010          ; Get first button
  bne .done                ; Jump to subprogram if not pressed

  lda #ready_str[7:0]      ; Load ready string lower address
  sta a0                   ; to a0
  lda #ready_str[15:8]     ; Load ready string higher address
  sta a1                   ; to a1
  jsr print_str            ; Print ready string
  lda #0b11000000          ; Move cursor to second line
  jsr lcd_instruction      ; Write instruction

  lda #serial_buffer[7:0]  ; Load serial buffer lower address
  sta a0                   ; to a0
  lda #serial_buffer[15:8] ; Load serial buffer higher address
  sta a1                   ; to a1

  lda #subprogram[7:0]     ; Load subprogram lower address
  sta a2                   ; to a2
  lda #subprogram[15:8]    ; Load subprogram higher address
  sta a3                   ; to a3

  ldx #0x10                ; Loop over 16 pages
  .page_write:             ; ...

  .chunk_write:            ; Loop over 4 chunks of 64 bytes
  jsr read_serial          ; Read 64 bytes from serial
  jsr write_to_rom         ; Write a0 to a2
  lda a2                   ; Increment subprogram lower address
  adc #0x40                ; By 64
  sta a2                   ; And write back
  bcc .chunk_write         ; Loop while not overflow
  clc                      ; Clear carry

  lda #"."                 ; Load a dot
  jsr print_char           ; Print a dot
  inc a3                   ; Increment subprogram higher address
  dex                      ; Decrement X
  bne .page_write          ; Loop until X equals zero

  lda #complete_str[7:0]   ; Load complete string lower address
  sta a0                   ; to a0
  lda #complete_str[15:8]  ; Load complete string higher address
  sta a1                   ; to a1
  jsr print_str

  jsr sleep                ; Sleep for 1 second
  jsr sleep                ; ...
  jsr sleep                ; ...

  lda #empty_str[7:0]      ; Load empty string lower address
  sta a0                   ; to a0
  lda #empty_str[15:8]     ; Load empty string higher address
  sta a1                   ; to a1
  jsr print_str

  .done:
  jmp (subprgm_reset_vec)  ; Jump to subprogram reset

; Data

ready_str:
#d "Ready for input"
#d "\0"

complete_str:
#d "Transfer complete"
#d "\0"

empty_str:
#d "\0"

; Subroutines


; Print the string with address in a0 to LCD
print_str:
  tya                   ; Transfer Y to A
  pha                   ; And push it onto the stack

  lda #0b00000001       ; Clear display
  jsr lcd_instruction   ; Write instruction

  lda #0b00000010       ; Return home
  jsr lcd_instruction   ; Write instruction

  ldy #0                ; Initalize Y register
  .char_loop:           ; Loop over characters

  lda (a0), y           ; Get a character from message, indexed by Y
  beq .done             ; Done with the printing
  jsr print_char        ; Print the character
  iny                   ; Increment Y
  jmp .char_loop        ; Loop over

  .done:                ; Done with the printing
  pla                   ; Pull Y from the stack
  tay                   ; And transfer it
  rts                   ; Return


; Read 64 bytes of ram from a0 and write to ROM at a2
write_to_rom:
  txa                   ; Transfer X to A
  pha                   ; And push it onto the stack
  tya                   ; Transfer Y to A
  pha                   ; And push it onto the stack

  ldy #0x00             ; Initialize Y to 0
  ldx #0x40             ; Initialize X to 64

  lda #0x01             ; Set /OE to 1
  sta PORTA             ; Disconnect rom output
  nop                   ; Let the IO mux do its job
  nop                   ; ...
  nop                   ; ...

  lda #0xaa             ; Program write mode by writing a magic sequence of values to specific addresses
  sta (0x5555 | 0x8000) ; ... Then we have 150 us to write the first byte
  lda #0x55             ; ... Then 150 us to write the next byte
  sta (0x2AAA | 0x8000) ; ... And so on until up to 64 bytes have been written
  lda #0xa0             ; ...
  sta (0x5555 | 0x8000) ; ...

  .byte_loop:
  lda (a0), y           ; Load byte
  sta (a2), y           ; Write byte
  iny                   ; Increment Y
  dex                   ; Decrement X
  bne .byte_loop        ; Loop over bytes

  lda #0x00             ; Set /OE to 0
  sta PORTA             ; Reconnect rom output
  nop                   ; Let the IO mux do its job
  nop                   ; Let the IO mux do its job
  nop                   ; ...

  ldy #0x00             ; Clear Y
  .wait_loop:           ; Loop until write is over
  lda (a2), y           ; Read ROM
  eor (a2), y           ; XOR with the same read
  bne .wait_loop        ; Wait until bit 6 stops toggling

  pla                   ; Pull Y from the stack
  tay                   ; And transfer it
  pla                   ; Pull X from the stack
  tax                   ; And transfer it
  rts                   ; Return

; Wait for data to be available on serial
wait_serial:
  lda UART_LSR          ; Load LSR
  and #LSR_DATRDY       ; Keep data ready bit
  bne .done             ; Done if data ready

  lda #MCR_RTSSET       ; Set RTS in case it's not already set
  sta UART_MCR          ; Write to MCR

  .wait_ready:          ; Wait data to be available
  lda UART_LSR          ; Load LSR
  and #LSR_DATRDY       ; Keep data ready bit
  beq .wait_ready       ; Wait for data ready

  .done:                ; Done
  rts                   ; return


; Read serial and write to address in s0
read_serial:
  txa                   ; Transfer X to A
  pha                   ; And push it onto the stack
  tya                   ; Transfer Y to A
  pha                   ; And push it onto the stack

  ldy #0x00             ; Initialize Y to 0
  ldx #0x40             ; Initialize X to 64

  lda #MCR_RTSSET       ; Set RTS in case it's not already set
  sta UART_MCR          ; Write to MCR

  .byte_loop:           ; Loop over bytes read/write

  .wait_ready:          ; Wait data to be available
  lda UART_LSR          ; Load LSR
  and #LSR_DATRDY       ; Keep data ready bit
  beq .wait_ready       ; Wait for data ready

  lda UART_RBR          ; Read byte
  sta serial_buffer, y  ; Write to serial buffer
  iny                   ; Increment Y
  dex                   ; Decrement X
  bne .byte_loop        ; Loop over bytes

  lda #MCR_RTSCLR       ; Clear RTS
  sta UART_MCR          ; Write to MCR

  pla                   ; Pull Y from the stack
  tay                   ; And transfer it
  pla                   ; Pull X from the stack
  tax                   ; And transfer it
  rts                   ; Return


; Configure the UART receiver
; Line control configuration:
; - Baud rate: 4807 Hz (1MHz / 16 / 13)
; - 8-bit characters
; - 2 stop bits
; - Enable even parity
; - No stick bit
; - No break
; FIFO configuration:
; - Disable FIFO
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

  lda #MCR_RTSCLR ; Clear RTS
  sta UART_MCR    ; Write to MCR

  pla             ; Pull A from the stack
  rts             ; Return

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
  tya             ; Transfer Y to A
  pha             ; And push it onto the stack

  ldy #0xff       ; Initialize Y to 255
loop1:            ; Outer loop
  ldx #0xff       ; Initialize X to 255
loop2:            ; Inner loop
  dex             ; Decrement X
  bne loop2       ; Jump to inner loop while X is not zero
  dey             ; Decrement Y
  bne loop1       ; Jump to outer loop while Y is not zero

  pla             ; Pull Y from the stack
  tay             ; And transfer it
  pla             ; Pull X from the stack
  tax             ; And transfer it
  rts             ; Return


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

