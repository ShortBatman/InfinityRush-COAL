
draw_score:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    mov al, 1           		; the color (navy blue)       
    mov cx, 232                 ; x
    mov dx, 0                   ; y
    mov si, 88                 ;width is 88 pixels, each col is 8 pixels wide, cols 29 to end of the row
    mov di, 9                  ;height is 9 pixels, rows 0 to 8
    call fill_rect

    mov si, draw_score_label		;draw_score_label = "SCORE: "
    mov dh, 0						;first row
    mov dl, 29                		;29-34 cols
    mov bl, 6          				;text color white    
    call print_str

    mov ax, [score]
    mov dh, 0
    mov dl, 35						;35-39 cols               
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
