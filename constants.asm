; Constants for the 6502 Ben Eater architecture

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

; UART constants
UART_RBR = 0x4000 ; Read-only
UART_THR = 0x4000 ; Write-only
UART_DLL = 0x4000
UART_IER = 0x4001
UART_DLM = 0x4001
UART_IIR = 0x4002 ; Read-only
UART_FCR = 0x4002 ; Write-only
UART_LCR = 0x4003
UART_MCR = 0x4004
UART_LSR = 0x4005
UART_MSR = 0x4006
UART_SCR = 0x4007

LCR_CS5 = 0b00000000    ; 5-bit character size
LCR_CS6 = 0b00000001    ; 6-bit character size
LCR_CS7 = 0b00000010    ; 7-bit character size
LCR_CS8 = 0b00000011    ; 8-bit character size
LCR_STOPB1 = 0b00000000 ; 1 stop bit
LCR_STOPB2 = 0b00000100 ; 2 stop bits
LCR_PARDIS = 0b00000000 ; Disable parity bit
LCR_PARENB = 0b00001000 ; Enable parity bit
LCR_PARODD = 0b00000000 ; Odd parity bit
LCR_PAREVE = 0b00010000 ; Even parity bit
LCR_STIDIS = 0b00000000 ; Disable sticky bit
LCR_STIENB = 0b00100000 ; Enable sticky bit
LCR_BRKDIS = 0b00000000 ; Disable break
LCR_BRKENB = 0b01000000 ; Enable break
LCR_DIVLTC = 0b10000000 ; Divisor Latch

; The corresponding ssty configuration is:
; "speed 4800 baud;" cs8 cstopb parenb -parodd -cmspar -hupcl clocal cread crtscts -onlcr
LCR_CONFIG = LCR_CS8 | LCR_STOPB2 | LCR_PARENB | LCR_PAREVE | LCR_STIDIS | LCR_BRKDIS

MCR_AUTRTS = 0b00100010 ; Auto CTS/RTS
MCR_RTSCLR = 0b00000000 ; Clear RTS
MCR_RTSSET = 0b00000010 ; Set RTS

FCR_FIFDIS = 0b00000000 ; Disable FIFO
FCR_FIFENB = 0b00000001 ; Enable FIFO
FCR_FIFRST = 0b00000110 ; Clear FIFOs (self-clearing bits)
FCR_RFTL01 = 0b00000000 ; Set receiver FIFO trigger level is 1
FCR_RFTL04 = 0b01000000 ; Set receiver FIFO trigger level is 4
FCR_RFTL08 = 0b10000000 ; Set receiver FIFO trigger level is 8
FCR_RFTL14 = 0b11000000 ; Set receiver FIFO trigger level is 14

FCR_CONFIG = FCR_FIFDIS

LSR_DATRDY = 0b00000001 ; Data ready
