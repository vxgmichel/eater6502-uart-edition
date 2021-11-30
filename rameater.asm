; Constants and banks for the 6502 Ben Eater architecture

; Also defines a boot routine that copies the program to the RAM
; before executing it. This allows the program to reprogram the
; EPROM if necessary.


; Multiplexer constants

PORTB = 0x6000
PORTA = 0x6001
DDRB = 0x6002
DDRA = 0x6003

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


; Banks
PAGE = 0x0100

#bankdef zeropage { #addr 0x0000, #size 0x0100 }
#bankdef stack    { #addr 0x0100, #size 0x0100 }
#bankdef ram      { #addr 0x0200, #size 0x3e00 }
#bankdef program  { #addr 0x3e00, #size 0x0200, #outp 8 * 0x7d00 }
#bankdef uart     { #addr 0x4000, #size 0x2000 }
#bankdef iomux    { #addr 0x6000, #size 0x2000 }
#bankdef romprg   { #addr 0xfd00, #size 0x0200 }
#bankdef bootprg  { #addr 0xff00, #size 0x00fa, #outp 8 * 0x7f00 }
#bankdef vectors  { #addr 0xfffa, #size 0x0006, #outp 8 * 0x7ffa }

#bank program
program:

#bank romprg
romprg_page0: #res 256
romprg_page1: #res 256

#bank bootprg
rom_reset:

  ; Copy program first page to ram
  ldx #0x00
  .ram_copy0:
  lda romprg_page0, x
  sta program, x
  inx
  bne .ram_copy0

  ; Copy program second page to ram
  ldx #0x00
  .ram_copy1:
  lda romprg_page1, x
  sta program + PAGE, x
  inx
  bne .ram_copy1

  ; Jump to the actual reset entry point
  jmp reset

rom_nmi:
  jmp nmi

rom_irq:
  jmp irq

#bank vectors
#d16   rom_nmi[7:0] @   rom_nmi[15:8] ; Non-maskable interrupt entry point
#d16 rom_reset[7:0] @ rom_reset[15:8] ; Reset entry point
#d16   rom_irq[7:0] @   rom_irq[15:8] ; Maskable interrupt entry point
