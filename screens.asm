; ============================================================
; screens.asm  -  start screen, end screen and live score
; (tasks M3 and M4).  %included at the bottom of infinity.asm,
; AFTER text.asm.  No org, no entry point.
;
; Needs (from Umer): fill_screen, fill_rect, draw_sprite,
;                    stone_sprites, [score], [end_reason]
; Needs (from text.asm): print_str, print_num, print_str_center
; ES = A000h and DS = CS when these are called.
; Every routine preserves all registers.
; ============================================================


; ------------------------------------------------------------
; draw_start_screen   (also callable as show_start_screen)
;   No input.
; ------------------------------------------------------------
show_start_screen:
draw_start_screen:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov al, 1                   ; dark navy background
    call fill_screen

    ; gold decorative lines above and below the title
    mov al, 7
    mov cx, 72                  ; x
    mov dx, 32                  ; y (just above text row 5)
    mov si, 176                 ; width
    mov di, 2                   ; height
    call fill_rect
    mov cx, 72
    mov dx, 54                  ; y (just below text row 5)
    mov si, 176
    mov di, 2
    call fill_rect

    ; game name, yellow, row 5
    mov si, draw_start_screen_title
    mov dh, 5
    mov bl, 10
    call print_str_center

    ; controls, cyan, row 8
    mov si, draw_start_screen_ctrl
    mov dh, 8
    mov bl, 12
    call print_str_center

    ; rules, rows 10 / 12 / 14
    mov si, draw_start_screen_rule1
    mov dh, 10
    mov bl, 6                   ; white
    call print_str_center

    mov si, draw_start_screen_rule2
    mov dh, 12
    mov bl, 11                  ; red
    call print_str_center

    mov si, draw_start_screen_rule3
    mov dh, 14
    mov bl, 6
    call print_str_center

    ; the 6 Infinity Stones in a row (pixel y = 140, x starts at 68,
    ; each 24 wide + 8 gap => total 184 pixels, centered on 320)
    mov bx, stone_sprites       ; BX walks the table of 6 pointers
    mov ax, 68                  ; AX = current x
    mov di, 6                   ; DI = stones left to draw
draw_start_screen_stone:
    push ax
    push bx
    push di
    mov si, [bx]                ; SI = address of this stone's sprite
    mov cx, ax                  ; CX = x
    mov dx, 140                 ; DX = y
    call draw_sprite
    pop di
    pop bx
    pop ax
    add bx, 2                   ; next pointer (words are 2 bytes)
    add ax, 32                  ; next x
    dec di
    jnz draw_start_screen_stone

    ; bottom line, yellow, row 22
    mov si, draw_start_screen_press
    mov dh, 22
    mov bl, 10
    call print_str_center

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_start_screen_title: db 'INFINITY RUSH', 0
draw_start_screen_ctrl:  db 'LEFT / RIGHT ARROWS : MOVE', 0
draw_start_screen_rule1: db 'ARC REACTOR=5 SHIELD=10 MJOLNIR=15', 0
draw_start_screen_rule2: db 'AVOID THE INFINITY STONES!', 0
draw_start_screen_rule3: db 'ROUND LASTS 2 MINUTES', 0
draw_start_screen_press: db 'PRESS ENTER TO START', 0


; ------------------------------------------------------------
; draw_end_screen   (also callable as show_end_screen)
;   No input.  Uses [end_reason] (0 = time's up, 1 = caught a stone)
;   and [score].
; ------------------------------------------------------------
show_end_screen:
draw_end_screen:
    push ax
    push bx
    push dx
    push si

    mov al, 1                   ; dark background
    call fill_screen

    cmp byte [end_reason], 1
    jne draw_end_screen_time    ; not 1 -> time's up

    ; ---- variant 1: caught an Infinity Stone ----
    mov si, draw_end_screen_snap
    mov dh, 6
    mov bl, 11                  ; red
    call print_str_center
    mov si, draw_end_screen_caught
    mov dh, 8
    mov bl, 11
    call print_str_center
    jmp draw_end_screen_score

draw_end_screen_time:
    ; ---- variant 2: time is up ----
    mov si, draw_end_screen_timeup
    mov dh, 6
    mov bl, 10                  ; yellow
    call print_str_center

draw_end_screen_score:
    mov si, draw_end_screen_final
    mov dh, 12
    mov bl, 6                   ; white
    call print_str_center

    mov ax, [score]
    mov dh, 14
    mov dl, 17                  ; 5-char field centered: (40-5)/2 = 17
    mov bl, 10                  ; yellow
    call print_num

    mov si, draw_end_screen_again
    mov dh, 22
    mov bl, 6
    call print_str_center

    pop si
    pop dx
    pop bx
    pop ax
    ret

draw_end_screen_snap:   db 'THE SNAP!', 0
draw_end_screen_caught: db 'YOU CAUGHT AN INFINITY STONE', 0
draw_end_screen_timeup: db "TIME'S UP!", 0
draw_end_screen_final:  db 'FINAL SCORE:', 0
draw_end_screen_again:  db 'PRESS ENTER TO PLAY AGAIN', 0


; ------------------------------------------------------------
; draw_score
;   No input.  Live score in the top-right of the HUD.
;   Clears pixels x 232..319, rows 0..8, then prints "SCORE:" at
;   columns 29..34 and the number at columns 35..39 (text row 0).
;   Text row 0 is pixel rows 0..7, so nothing goes below row 9.
; ------------------------------------------------------------
draw_score:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov al, 1                   ; HUD navy
    mov cx, 232                 ; x
    mov dx, 0                   ; y
    mov si, 88                  ; width  (232 + 88 = 320)
    mov di, 9                   ; height (rows 0..8)
    call fill_rect

    mov si, draw_score_label
    mov dh, 0
    mov dl, 29                  ; 29 * 8 = 232 pixels
    mov bl, 6                   ; white
    call print_str

    mov ax, [score]
    mov dh, 0
    mov dl, 35                  ; 35..39 -> ends at column 39
    mov bl, 6
    call print_num

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_score_label: db 'SCORE:', 0


; ------------------------------------------------------------
; draw_hud
;   No input.  The part of the HUD that is mine = the score.
;   (Umer's draw_background already draws the HUD bar itself.)
; ------------------------------------------------------------
draw_hud:
    call draw_score
    ret
