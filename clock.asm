; Subprogram for a 12-hour clock
; Can be configured using key presses.
;
; Up/Down keys are used to increment/decrement
; while Left/Right keys loop over the following position:
; - Tens of hours:    +/- 4 hours
; - Hours:            +/- 1 hour
; - Tens of minutes:  +/- 10 minutes
; - Minutes:          +/- 1 minute
; - Tens of seconds:  +/- 10 seconds
; - Seconds:          +/- 1 second
; - Hidden cursor
;
; On hidden cursor position:
; - Up key: toggle between 12-hour and 24-hour mode
; - Down key: synchronize the ticking

#include "layouts/subeater.asm"


; Allocate a string buffer

#bank ram
time_mode: #res 1

MODE_24 = 0
MODE_12 = 1


; Main program
#bank program

reset:
  jsr lcd_init           ; Init LCD display
  jsr event_init         ; Init event module

  wrb #MODE_24 time_mode ; Use 24-hour mode by default
  jsr update_display     ; Show time on the LCD
  lda #4                 ; Move cursor
  jsr lcd_seek           ; To postion 4
  jsr lcd_blink_on       ; Blink cursor

  .main:                 ; Event loop

  jsr event_pop          ; Pop events
  sta r0                 ; Store in r0

  lda r0                 ; Load events
  and #EVENT_LEFT        ; Keep left event
  beq .end_left          ; No left event
  jsr on_left            ; Call left event handler
  .end_left:

  lda r0                 ; Load events
  and #EVENT_RIGHT       ; Keep right event
  beq .end_right         ; No right event
  jsr on_right           ; Call right event handler
  .end_right:

  lda r0                 ; Load events
  and #EVENT_UP          ; Keep up event
  beq .end_up            ; No up event
  jsr on_up              ; Call up event handler
  .end_up:

  lda r0                 ; Load events
  and #EVENT_DOWN        ; Keep down event
  beq .end_down          ; No down event
  jsr on_down            ; Call down event handler
  .end_down:

  lda r0                 ; Load events
  and #EVENT_SECOND      ; Keep second event
  beq .end_second        ; No second event
  jsr update_display     ; Update display
  .end_second:

  jmp .main              ; Loop over


; Up handler
on_up:
  jsr lcd_tell            ; Get cursor position
  beq .no_edit            ; Go to no edit handler
  cmp #4                  ; Position 4
  beq .ten_hours          ; Go to ten hours handler
  cmp #5                  ; Position 5
  beq .hours              ; Go to hours handler
  cmp #7                  ; Position 7
  beq .ten_minutes        ; Go to ten minutes hander
  cmp #8                  ; Position 8
  beq .minutes            ; Go to minutes handler
  cmp #10                 ; Position 10
  beq .ten_seconds        ; Go to ten seconds handler
  cmp #11                 ; Position 11
  beq .seconds            ; Go to seconds handler
  jmp .done               ; Otherwise we're done

  .no_edit:
    lda time_mode         ; Load time mode
    eor #1                ; Toggle time mode
    sta time_mode         ; Write back
    jmp .done             ; We're done

  .ten_hours:
    wrw #4*3600 a0        ; Add 4 hours
    jsr time_add_seconds  ; to current time
    jmp .done             ; We're done

  .hours:
    wrw #60*60 a0         ; Add 1 hour
    jsr time_add_seconds  ; to current time
    jmp .done             ; We're done

  .ten_minutes:
    wrw #10*60 a0         ; Add 10 minutes
    jsr time_add_seconds  ; to current time
    jmp .done             ; We're done

  .minutes:
    wrw #60 a0            ; Add 1 minute
    jsr time_add_seconds  ; to current time
    jmp .done             ; We're done

  .ten_seconds:
    wrw #10 a0            ; Add 10 seconds
    jsr time_add_seconds  ; to current time
    jmp .done             ; We're done

  .seconds:
    wrw #1 a0             ; Add 1 second
    jsr time_add_seconds  ; to current time
    jmp .done             ; We're done

  .done:
  jsr update_display      ; Update the display
  rts                     ; Return from subroutine


; Down handler
on_down:
  jsr lcd_tell            ; Get cursor position
  beq .no_edit            ; Go to no edit handler
  cmp #4                  ; Position 4
  beq .ten_hours          ; Go to ten hours handler
  cmp #5                  ; Position 5
  beq .hours              ; Go to hours handler
  cmp #7                  ; Position 7
  beq .ten_minutes        ; Go to ten minutes hander
  cmp #8                  ; Position 8
  beq .minutes            ; Go to minutes handler
  cmp #10                 ; Position 10
  beq .ten_seconds        ; Go to ten seconds handler
  cmp #11                 ; Position 11
  beq .seconds            ; Go to seconds handler
  jmp .done               ; Otherwise we're done

  .no_edit:
    jsr time_sync         ; Synchronize seconds
    jmp .done             ; We're done

  .ten_hours:
    wrw #4*3600 a0        ; Subtract 4 hours
    jsr time_sub_seconds  ; to current time
    jmp .done             ; We're done

  .hours:
    wrw #60*60 a0         ; Subtract 1 hour
    jsr time_sub_seconds  ; to current time
    jmp .done             ; We're done

  .ten_minutes:
    wrw #10*60 a0         ; Subtract 10 minutes
    jsr time_sub_seconds  ; to current time
    jmp .done             ; We're done

  .minutes:
    wrw #60 a0            ; Subtract 1 minute
    jsr time_sub_seconds  ; to current time
    jmp .done             ; We're done

  .ten_seconds:
    wrw #10 a0            ; Subtract 10 seconds
    jsr time_sub_seconds  ; to current time
    jmp .done             ; We're done

  .seconds:
    wrw #1 a0             ; Subtract 1 second
    jsr time_sub_seconds  ; to current time
    jmp .done             ; We're done

  .done:
  jsr update_display      ; Update the display
  rts                     ; Return from subroutine



; Left handler
on_left:
  jsr lcd_tell
  beq .start_edit
  cmp #11
  beq .move_once
  cmp #10
  beq .move_twice
  cmp #8
  beq .move_once
  cmp #7
  beq .move_twice
  cmp #5
  beq .move_once
  cmp #4
  beq .stop_edit
  jmp .done

  .start_edit:
  lda #11
  jsr lcd_seek
  jsr lcd_blink_on
  jmp .done

  .stop_edit:
  lda #0
  jsr lcd_seek
  jsr lcd_blink_off
  jmp .done

  .move_twice:
  jsr lcd_move_left
  .move_once:
  jsr lcd_move_left

  .done:
  rts


; Right handler
on_right:
  jsr lcd_tell
  beq .start_edit
  cmp #4
  beq .move_once
  cmp #5
  beq .move_twice
  cmp #7
  beq .move_once
  cmp #8
  beq .move_twice
  cmp #10
  beq .move_once
  cmp #11
  beq .stop_edit
  jmp .done

  .start_edit:
  lda #4
  jsr lcd_seek
  jsr lcd_blink_on
  jmp .done

  .stop_edit:
  lda #0
  jsr lcd_seek
  jsr lcd_blink_off
  jmp .done

  .move_twice:
  jsr lcd_move_right
  .move_once:
  jsr lcd_move_right

  .done:
  rts


; Update display
update_display:
  lda r0               ; Push r0
  pha                  ; Onto the stack
  lda r1               ; Push r1
  pha                  ; Onto the stack
  lda r2               ; Push r2
  pha                  ; Onto the stack

  jsr lcd_tell         ; Get cursor position
  sta r2               ; Save in r2

  jsr lcd_clear        ; Clear the screen

  lda #4               ; Load position 4
  jsr lcd_seek         ; Move curosor

  lda time_mode        ; Load time mode
  cmp #MODE_12         ; Test 12-hour mode
  bne .mode_24         ; Go to the right mode

  .mode_12:
  jsr time_12_hour_str ; Get time as text
  wrw a2 r0            ; Save a2 in r0
  jsr lcd_print_str    ; Print to LCD display
  lda #64 + 7          ; Load position 7 on second row
  jsr lcd_seek         ; Move cursor
  wrw r0 a0            ; Write second string address to a0
  jsr lcd_print_str    ; Print AM/PM
  jmp .time_mode_done

  .mode_24:
  jsr time_24_hour_str ; Get time as text
  jsr lcd_print_str    ; Print to LCD display
  .time_mode_done:

  lda r2               ; Load r2
  jsr lcd_seek         ; Restore cursor position

  pla                  ; Pop r0 from the stack
  sta r2               ; And write it back
  pla                  ; Pop r0 from the stack
  sta r1               ; And write it back
  pla                  ; Pop r0 from the stack
  sta r0               ; And write it back
  rts                  ; Return from subroutine

; Interrupt

nmi:
  rti

irq:
  jsr event_irq
  rti

; Libraries

#include "libraries/lcd.asm"
#include "libraries/rom.asm"
#include "libraries/time.asm"
#include "libraries/event.asm"
