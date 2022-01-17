; Subprogram for a 12-hour clock
; Can be configured using key presses

#include "layouts/subeater.asm"


; Allocate a string buffer

#bank ram
string_buffer: #res 256


; Main program
#bank program

reset:
  jsr lcd_init          ; Init LCD
  jsr time_init         ; Init time

  jsr update_display    ; Show time on the LCD
  lda #4                ; Move cursor
  jsr lcd_seek          ; To postion 4
  jsr lcd_blink_on      ; Blink cursor

  .main:                ; Event loop

  jsr time_pop_events   ; Pop events
  sta r0                ; Store in r0

  lda r0                ; Load events
  and #EVENT_LEFT       ; Keep left event
  beq .end_left         ; No left event
  jsr on_left           ; Call left event handler
  .end_left:

  lda r0                ; Load events
  and #EVENT_RIGHT      ; Keep right event
  beq .end_right        ; No right event
  jsr on_right          ; Call right event handler
  .end_right:

  lda r0                ; Load events
  and #EVENT_UP         ; Keep up event
  beq .end_up           ; No up event
  jsr on_up             ; Call up event handler
  .end_up:

  lda r0                ; Load events
  and #EVENT_DOWN       ; Keep down event
  beq .end_down         ; No down event
  jsr on_down           ; Call down event handler
  .end_down:

  lda r0                ; Load events
  and #EVENT_SECOND     ; Keep second event
  beq .end_second       ; No second event
  jsr update_display    ; Update display
  .end_second:

  jmp .main             ; Loop over


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
    jsr time_sync         ; Synchronize seconds
    jmp .done             ; We're done

  .ten_hours:
    wrw #6*3600 a0        ; Add 6 hours
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
    wrw #6*3600 a0        ; Subtract 6 hours
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
  jmp.done

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
  jmp.done

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

  jsr lcd_tell         ; Get cursor position
  sta r0               ; Save in r0

  jsr lcd_clear        ; Clear the screen

  lda #" "             ; Write four spaces characters
  jsr lcd_print_char   ; to center the text
  jsr lcd_print_char   ;
  jsr lcd_print_char   ;
  jsr lcd_print_char   ;

  jsr time_as_str      ; Get time as text
  jsr lcd_print_str    ; Print to LCD display

  lda r0               ; Load r0
  jsr lcd_seek         ; Restore cursor position

  pla                  ; Pop r0 from the stack
  sta r0               ; And write it back
  rts                  ; Return from subroutine

; Interrupt

nmi:
  rti

irq:
  jsr time_irq
  rti

; Libraries

#include "libraries/lcd.asm"
#include "libraries/rom.asm"
#include "libraries/math.asm"
#include "libraries/decimal.asm"
#include "libraries/time.asm"
