; Library serial communication using the UART chip
#once

; UART registers

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


; UART Line Control register values

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


; Default Line Control register configuration

; The corresponding ssty configuration is:
; "speed 4800 baud;" cs8 cstopb parenb -parodd -cmspar -hupcl clocal cread crtscts -opost
LCR_CONFIG = LCR_CS8 | LCR_STOPB2 | LCR_PARENB | LCR_PAREVE | LCR_STIDIS | LCR_BRKDIS


; Model Control Register values

MCR_AUTRTS = 0b00100010 ; Auto CTS/RTS
MCR_RTSCLR = 0b00000000 ; Clear RTS
MCR_RTSSET = 0b00000010 ; Set RTS


; FIFO Control Register values

FCR_FIFDIS = 0b00000000 ; Disable FIFO
FCR_FIFENB = 0b00000001 ; Enable FIFO
FCR_FIFRST = 0b00000110 ; Clear FIFOs (self-clearing bits)
FCR_RFTL01 = 0b00000000 ; Set receiver FIFO trigger level is 1
FCR_RFTL04 = 0b01000000 ; Set receiver FIFO trigger level is 4
FCR_RFTL08 = 0b10000000 ; Set receiver FIFO trigger level is 8
FCR_RFTL14 = 0b11000000 ; Set receiver FIFO trigger level is 14


; Default FIFO Control Register configuration

FCR_CONFIG = FCR_FIFENB | FCR_FIFRST | FCR_RFTL01


; Masks for Line Status Register

LSR_DATRDY = 0b00000001 ; Data ready


; Allocate 256 bytes on the RAM for a global buffer

#bank ram
#align 256
serial_buffer: #res 256


; Add serial functions to the program

#bank program

; Configure the UART receiver
; Line control configuration:
; - Baud rate: 115200 (1.8432MHz / 16 / 1)
; - 8-bit characters
; - 2 stop bits
; - Enable even parity
; - No stick bit
; - No break
; FIFO configuration:
; - Enable FIFO with trigger level at 1
uart_init:
  pha             ; Push A onto the stack

  lda #LCR_DIVLTC  ; Set the divisor latch
  sta UART_LCR     ; Write to LCR

  lda #0x01       ; Set the divisor lower byte (1)
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


; Wait for data to be available on serial
uart_wait_read:
  lda UART_LSR          ; Load LSR
  and #LSR_DATRDY       ; Keep data ready bit
  bne .done             ; Done if data ready

  lda #MCR_AUTRTS       ; Set autoflow control
  sta UART_MCR          ; Write to MCR

  .wait_ready:          ; Wait data to be available
  lda UART_LSR          ; Load LSR
  and #LSR_DATRDY       ; Keep data ready bit
  beq .wait_ready       ; Wait for data ready

  lda #MCR_RTSCLR       ; Clear RTS and autoflow control
  sta UART_MCR          ; Write to MCR

  .done:                ; Done
  rts                   ; return


; Read one byte from serial
uart_read_one:
  jsr uart_wait_read
  lda UART_RBR
  rts

; Read A bytes from serial and write to address serial_buffer
uart_read:
  sta s0
  txa                   ; Transfer X to A
  pha                   ; And push it onto the stack
  tya                   ; Transfer Y to A
  pha                   ; And push it onto the stack

  lda s0                ; Load argument to
  tax                   ; Transfer argument to X
  ldy #0x00             ; Initialize Y to 0

  .byte_loop:           ; Loop over bytes read/write
  jsr uart_wait_read    ; Wait for data to be available
  lda UART_RBR          ; Read byte
  sta serial_buffer, y  ; Write to serial buffer
  iny                   ; Increment Y
  dex                   ; Decrement X
  bne .byte_loop        ; Loop over bytes

  pla                   ; Pull Y from the stack
  tay                   ; And transfer it
  pla                   ; Pull X from the stack
  tax                   ; And transfer it
  lda s0                ; Restore argument to A
  rts                   ; Return


; Read bytes to a0 until character A is detected
; Return number of written bytes in A
uart_readuntil:
  sta s0              ; Store argument to s0
  tya                 ; Push Y onto the stack
  pha                 ;
  lda r0              ; Push r0 onto the stack
  pha                 ;
  lda s0              ; Store argument to r0
  sta r0              ;

  ldy #0x00           ; Initialize Y to 0
  .byte_loop:         ; Loop over bytes
  jsr uart_wait_read  ; Wait for data
  lda UART_RBR        ; Load data
  sta (a0), y         ; Write to buffer
  iny                 ; Increment Y
  cmp r0              ; Compare read value to s0
  bne .byte_loop      ;

  lda #0x00           ; Write a null byte
  sta (a0), y         ; at the end

  tya                 ; Write Y to s0
  sta s0              ;
  pla                 ; Restore r0 from the stack
  sta r0              ;
  pla                 ; Restore Y from the stack
  tay                 ;
  lda s0              ; Load s0
  rts                 ; Return from subroutine


; Read bytes to a0 until a line feed is detected
; Return number of written bytes in A
uart_readline:
  lda #"\n"
  jsr uart_readuntil
  rts


; Write line from buffer in a0
uart_writeline:
  tya             ; Push Y onto the stach
  pha

  ldy #0x00       ; Initialize Y to 0

  .byte_loop:     ; Loop over bytes

  .wait_ready:
  lda UART_LSR
  and #0b01100000
  beq .wait_ready

  lda (a0), y     ; Load next byte
  beq .done       ; Done if null byte
  sta UART_THR    ; Write to UART

  iny             ; Increment Y
  jmp .byte_loop  ; Loop over bytes

  .done:          ; Done with the loop
  lda #"\n"       ; Write a line feed
  sta UART_THR    ; to UART

  pla             ; Restore Y
  tay             ;
  rts             ; Return
