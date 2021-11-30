; Constants and banks for the 6502 Ben Eater architecture


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

#bankdef zeropage { #addr 0x0,    #size 0x100 }
#bankdef stack    { #addr 0x100,  #size 0x100 }
#bankdef ram      { #addr 0x200,  #size 0x3e00 }
#bankdef uart     { #addr 0x4000, #size 0x2000 }
#bankdef iomux    { #addr 0x6000, #size 0x2000 }
#bankdef program  { #addr 0x8000, #size 0x7ffa, #outp 8 * 0x0000 }
#bankdef vectors  { #addr 0xfffa, #size 0x6,    #outp 8 * 0x7ffa }

#bank vectors
#d16   nmi[7:0] @   nmi[15:8] ; Non-maskable interrupt entry point
#d16 reset[7:0] @ reset[15:8] ; Reset entry point
#d16   irq[7:0] @   irq[15:8] ; Maskable interrupt entry point