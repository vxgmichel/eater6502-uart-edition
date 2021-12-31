; A boot program for the eater 6502 architecture

; The boot program copies itself in the ram,
; Read a 4KB program from the serial line,
; Write it permanently to the EPROM and
; Run the subprogram


#include "map/rameater.asm"



; Main program

#bank program
reset:

  ldx #0xff                ; Initialize the stack pointer at the end of its dedicated page
  txs                      ; ...

  jsr uart_init            ; Configure UART receiver
  jsr lcd_init             ; Initialize the LCD display
  jsr lcd_clear            ; Clear LCD display

  lda PORTA                ; Load port A
  and #0b00000010          ; Get first button
  bne .done                ; Jump to subprogram if not pressed

  lda #ready_str[7:0]      ; Load ready string lower address
  sta a0                   ; to a0
  lda #ready_str[15:8]     ; Load ready string higher address
  sta a1                   ; to a1
  jsr lcd_print_str        ; Print ready string
  lda #0b11000000          ; Move cursor to second line
  jsr lcd_instruction      ; Write instruction
  jsr sleep                ; Wait at least 5 ms for the ROM write protection

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
  lda #0x40                ; Load 64 as argument
  jsr uart_read            ; Read 64 bytes from serial
  jsr rom_write            ; Write a0 to a2
  lda a2                   ; Increment subprogram lower address
  clc                      ; Clear carry
  adc #0x40                ; By 64
  sta a2                   ; And write back
  bcc .chunk_write         ; Loop while not overflow
  clc                      ; Clear carry

  lda #"."                 ; Load a dot
  jsr lcd_print_char       ; Print a dot
  inc a3                   ; Increment subprogram higher address
  dex                      ; Decrement X
  bne .page_write          ; Loop until X equals zero

  jsr lcd_clear            ; Clear LCD display

  lda #complete_str[7:0]   ; Load complete string lower address
  sta a0                   ; to a0
  lda #complete_str[15:8]  ; Load complete string higher address
  sta a1                   ; to a1
  jsr lcd_print_str        ; Print complete_str to LCD display

  jsr sleep                ; Sleep for 1 second
  jsr sleep                ; ...
  jsr sleep                ; ...

  jsr lcd_clear            ; Clear LCD display

  .done:
  jmp (subprgm_reset_vec)  ; Jump to subprogram reset


; Static data

ready_str:
#d "Ready for input"
#d "\0"

complete_str:
#d "Transfer        xxxxxxxxxxxxxxxxxxxxxxxx"
#d "      Complete !"
#d "\0"

empty_str:
#d "\0"


; Interrupt handling

nmi:
irq:
  rti


; Libraries

#include "lib/lcd.asm"
#include "lib/uart.asm"
#include "lib/rom.asm"