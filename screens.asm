; screens.asm  -  start screen, end screen and live score
; (tasks M3 and M4).  


show_start_screen:
draw_start_screen:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov al, 1                   ; dark navy back
    call fill_screen

    
    mov al, 7
    mov cx, 72                 
    mov dx, 32                  
    mov si, 176                 ; width
    mov di, 2                     ; height
    call fill_rect
    mov cx, 72
    mov dx, 54                 
    mov si, 176
    mov di, 2
    call fill_rect

  
    mov si, draw_start_screen_title
    mov dh, 5
    mov bl, 10
    call print_str_center

  
    mov si, draw_start_screen_ctrl
    mov dh, 8
    mov bl, 12
    call print_str_center

    ;  rows 10 / 12 / 14
    mov si, draw_start_screen_rule1
    mov dh, 10
    mov bl, 6                  
    call print_str_center

    mov si, draw_start_screen_rule2
    mov dh, 12
    mov bl, 11                
    call print_str_center

    mov si, draw_start_screen_rule3
    mov dh, 14
    mov bl, 6
    call print_str_center

   
    mov bx, stone_sprites      
    mov ax, 68                 
    mov di, 6                   
draw_start_screen_stone:
    push ax
    push bx
    push di
    mov si, [bx]                
    mov cx, ax                  ; CX = x
    mov dx, 140                 ; DX = y
    call draw_sprite
    pop di
    pop bx
    pop ax
    add bx, 2                  
    add ax, 32                  
    dec di
    jnz draw_start_screen_stone

  
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



show_end_screen:
draw_end_screen:
    push ax
    push bx
    push dx
    push si

    mov al, 1                
    call fill_screen

    cmp byte [end_reason], 1
    jne draw_end_screen_time  

    ; caught infinity stone
    mov si, draw_end_screen_snap
    mov dh, 6
    mov bl, 11                  
    call print_str_center
    mov si, draw_end_screen_caught
    mov dh, 8
    mov bl, 11
    call print_str_center
    jmp draw_end_screen_score

draw_end_screen_time:
    ; time is up 
    mov si, draw_end_screen_timeup
    mov dh, 6
    mov bl, 10                 
    call print_str_center

draw_end_screen_score:
    mov si, draw_end_screen_final
    mov dh, 12
    mov bl, 6                  
    call print_str_center

    mov ax, [score]
    mov dh, 14
    mov dl, 17                 
    mov bl, 10                
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


draw_score:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov al, 1                  
    mov cx, 232                 ; x
    mov dx, 0                   ; y
    mov si, 88                 
    mov di, 9                  
    call fill_rect

    mov si, draw_score_label
    mov dh, 0
    mov dl, 29                
    mov bl, 6              
    call print_str

    mov ax, [score]
    mov dh, 0
    mov dl, 35               
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


draw_hud:
    call draw_score
    ret

; Needs (from Umer): fill_screen, fill_rect, draw_sprite,
;                    stone_sprites, [score], [end_reason]