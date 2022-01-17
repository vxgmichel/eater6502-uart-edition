; A subprogram to update the bootloader.


#include "layouts/ramsubeater.asm"

; Reserve a string buffer in the ram

#bank ram
#align 32
string_buffer: #res 32


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

  lda #2                   ; Wait 20 ms
  jsr time_busy_sleep      ; for the ROM write protection to fade out

  wrw #0x8000 r0           ; Load address 0x8000 to r0-r1
  ldx #0x80                ; Loop over 128 pages
  .page_write:             ; ...

  .chunk_write:            ; Loop over 4 chunks of 64 bytes
  lda #0x40                ; Load 64 as argument
  jsr uart_read            ; Read 64 bytes from serial
  wrw #serial_buffer a0    ; Load serial buffer address to a0-a1
  wrw r0 a2                ; Write current address to a2
  jsr rom_write            ; Write a0 to a2
  lda r0                   ; Increment lower address
  clc                      ; Clear carry
  adc #0x40                ; By 64
  sta r0                   ; And write back
  bcc .chunk_write         ; Loop while not overflow
  clc                      ; Clear carry

  lda r1                   ; Load higher address
  and #0b01111111          ; Clear MSB
  lsr a                    ; Divide by 2
  lsr a                    ; Divide by 2
  sta a0                   ; Store in a0
  wrb #0 a1                ; Load 0 to a1
  wrw #string_buffer a2    ; Load string buffer
  jsr to_base10            ; Convert to base 10

  wrw #string_buffer a0    ; Load string buffer as argument
  jsr lcd_clear_row        ; Clear row
  jsr lcd_print_str        ; Print it
  wrw #total_str a0        ; Load total string address
  jsr lcd_print_str        ; Print it

  dex                      ; Decrement X
  txa                      ; Transfer X to A
  inx                      ; Reincrement X
  and #0b00000000100       ; Keep third lowest bit
  lsr a                    ; Shift it left
  lsr a                    ; Shift it left
  sta PORTA                ; Toggle the LED

  inc r1                   ; Increment higher address
  clc                      ; Clear carry
  dex                      ; Decrement X
  bne .page_write          ; Loop until X equals zero

  jsr lcd_clear            ; Clear LCD display

  wrw #complete_str a0     ; Load complete string address to a0-a1
  jsr lcd_print_str        ; Print complete_str to LCD display

  lda #50                  ; Load 50 * 10 ms
  jsr time_busy_sleep      ; Sleep for 0.5 seconds

  .done:
  jmp (boot_reset)         ; Jump to bootloader reset


; Static data

ready_str:
#d "Bootpgrm updater"
#d "\0"

complete_str:
#d "Transfer        xxxxxxxxxxxxxxxxxxxxxxxx"
#d "      Complete !"
#d "\0"

total_str:
#d " / 32 KB"
#d "\0"

empty_str:
#d "\0"


; Interrupt handling

nmi:
  rti

irq:
  rti

; Libraries

#include "libraries/lcd.asm"
#include "libraries/rom.asm"
#include "libraries/time.asm"
#include "libraries/uart.asm"
#include "libraries/decimal.asm"
