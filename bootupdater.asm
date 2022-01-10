; A subprogram to update the bootloader.


#include "layouts/subeater.asm"


; Main program

#bank program
reset:

  ldx #0xff                ; Initialize the stack pointer at the end of its dedicated page
  txs                      ; ...

  jsr uart_init            ; Configure UART receiver
  jsr lcd_init             ; Initialize the LCD display
  jsr lcd_clear            ; Clear LCD display

  wrw #ready_str a0        ; Load ready string address to a0-a1
  jsr lcd_print_str        ; Print ready string
  lda #0b11000000          ; Move cursor to second line
  jsr lcd_instruction      ; Write instruction
  jsr sleep                ; Wait at least 5 ms for the ROM write protection to fade out

  wrw #serial_buffer a0    ; Load serial buffer address to a0-a1
  wrw #bootprogram a2      ; Load romprogram address to a2-a3

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

  jsr lcd_del_char
  lda #"="
  jsr lcd_print_char
  lda #">"                 ; Load a star
  jsr lcd_print_char       ; Print a star

  txa                      ; Transfer X to A
  and #0b00000000001       ; Keep lowest bit
  eor #0b00000000001       ; Invert it
  sta PORTA                ; Toggle the LED

  inc a3                   ; Increment subprogram higher address
  clc                      ; Clear carry
  dex                      ; Decrement X
  bne .page_write          ; Loop until X equals zero

  jsr lcd_clear            ; Clear LCD display

  wrw #complete_str a0     ; Load complete string address to a0-a1
  jsr lcd_print_str        ; Print complete_str to LCD display

  jsr sleep                ; Sleep for 1 second
  jsr sleep                ; ...
  jsr sleep                ; ...

  .done:
  jmp .done


; Static data

ready_str:
#d "Bootpgrm updater"
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

#include "libraries/lcd.asm"
#include "libraries/uart.asm"
#include "libraries/rom.asm"
