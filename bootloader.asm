; A bootloader program for the eater 6502 architecture

; When started with button 1 pressed, the bootloader program:
; - reads a 4KB subprogram from the serial line
; - writes it permanently to the EPROM
; - then run the subprogram
; If button 1 is **not** pressed after a reset, the subprogram is run.

#include "layouts/booteater.asm"


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

  wrw #ready_str a0        ; Load ready string address to a0-a1
  jsr lcd_print_str        ; Print ready string
  lda #0b11000000          ; Move cursor to second line
  jsr lcd_instruction      ; Write instruction
  jsr sleep                ; Wait at least 5 ms for the ROM write protection to fade out

  wrw #serial_buffer a0    ; Load serial buffer address to a0-a1
  wrw #subprogram a2       ; Load subprogram address to a2-a3

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
  jsr lcd_print_char       ; Print it

  dex                      ; Decrement X
  txa                      ; Transfer X to A
  inx                      ; Reincrement X
  and #0b00000000100       ; Keep third lowest bit
  lsr a                    ; Shift it left
  lsr a                    ; Shift it left
  sta PORTA                ; Toggle the LED

  inc a3                   ; Increment subprogram higher address
  dex                      ; Decrement X
  bne .page_write          ; Loop until X equals zero

  jsr lcd_clear            ; Clear LCD display

  wrw #complete_str a0     ; Load complete string address to a0-a1
  jsr lcd_print_str        ; Print complete_str to LCD display

  jsr sleep                ; Sleep for 1 second
  jsr sleep                ; ...
  jsr sleep                ; ...
  jsr sleep                ; ...
  jsr sleep                ; ...

  jsr lcd_clear            ; Clear LCD display

  .done:
  jmp (subprogram_reset_vec)  ; Jump to subprogram reset


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
  jmp (subprogram_nmi_vec)

irq:
  jmp (subprogram_irq_vec)


; Libraries

#include "libraries/lcd.asm"
#include "libraries/uart.asm"
#include "libraries/rom.asm"
