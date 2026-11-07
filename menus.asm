; menus.asm - cleaner start menu and end menu (uses print_str, print_str_center, print_num from text.asm)

; SI = bitmap (dw width, dw height, then the pixel bytes), CX = x, DX = y. Colour 0 = transparent
draw_bitmap:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    lodsw
    mov bp,ax              ; BP = width
    lodsw
    mov bx,ax              ; BX = rows left
    push cx
    mov di,dx
    mov cl,8
    shl di,cl              ; y*256
    mov cl,6
    shl dx,cl              ; y*64
    add di,dx              ; y*320
    pop cx
    add di,cx              ; + x
    cld
bitmap_row:
    push di
    mov cx,bp
bitmap_px:
    lodsb
    cmp al,0
    je bitmap_skip
    mov [es:di],al
bitmap_skip:
    inc di
    loop bitmap_px
    pop di
    add di,320
    dec bx
    jnz bitmap_row
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; CX=x, DX=y, SI=width, DI=height, AL=border colour. Dark panel with a coloured border
menu_box:
    push ax
    push cx
    push dx
    push si
    push di
    call fill_rect         ; border colour fills the whole box
    add cx,2
    add dx,2
    sub si,4
    sub di,4
    mov al,29              ; dark blue inside
    call fill_rect
    pop di
    pop si
    pop dx
    pop cx
    pop ax
    ret

; BX = table of rectangles (x, y, width, height, colour), ended by 0xFFFF
menu_rects:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
menu_rect_loop:
    mov cx,[bx]
    cmp cx,0xFFFF
    je menu_rect_done
    mov dx,[bx+2]
    mov si,[bx+4]
    mov di,[bx+6]
    mov ax,[bx+8]
    call fill_rect
    add bx,10
    jmp menu_rect_loop
menu_rect_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; dark background with stars and a strip of lava at the bottom
menu_background:
    push ax
    push bx
    mov al,1
    call fill_screen
    mov bx,menu_bg_table
    call menu_rects
    pop bx
    pop ax
    ret

draw_start_menu:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    call menu_background
    mov si,banner_title
    mov cx,(320-BANNER_TITLE_W)/2
    mov dx,10
    call draw_bitmap
    mov si,menu_txt_ctrl
    mov dh,5
    mov bl,12
    call print_str_center
    mov al,7               ; left panel: what to catch
    mov cx,16
    mov dx,60
    mov si,160
    mov di,100
    call menu_box
    mov al,11              ; right panel: what to avoid
    mov cx,188
    mov dx,60
    mov si,116
    mov di,100
    call menu_box
    mov si,menu_txt_catch
    mov dh,8
    mov dl,3
    mov bl,10
    call print_str
    mov si,menu_txt_avoid
    mov dh,8
    mov dl,24
    mov bl,11
    call print_str
    mov si,sprite_arc
    mov cx,32
    mov dx,80
    call draw_sprite
    mov si,sprite_shield
    mov dx,104
    call draw_sprite
    mov si,sprite_mjolnir
    mov dx,128
    call draw_sprite
    mov si,menu_txt_pts5
    mov dh,11
    mov dl,8
    mov bl,6
    call print_str
    mov si,menu_txt_pts10
    mov dh,14
    call print_str
    mov si,menu_txt_pts15
    mov dh,17
    call print_str
    mov bx,stone_sprites   ; the six stones, two rows of three
    mov di,menu_stone_pos
    mov bp,6
menu_stone_loop:
    mov si,[bx]
    mov cx,[di]
    mov dx,[di+2]
    call draw_sprite
    add bx,2
    add di,4
    dec bp
    jnz menu_stone_loop
    mov si,menu_txt_any
    mov dh,17
    mov dl,24
    mov bl,6
    call print_str
    mov si,menu_txt_ends
    mov dh,18
    call print_str
    mov si,menu_txt_round
    mov dh,21
    mov bl,23
    call print_str_center
    mov si,menu_txt_press
    mov dh,22
    mov bl,10
    call print_str_center
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

draw_end_menu:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    call menu_background
    cmp byte [end_reason],1
    jne menu_end_time
    mov si,banner_snap     ; caught a stone
    mov cx,(320-BANNER_SNAP_W)/2
    mov dx,24
    call draw_bitmap
    mov si,[stone_sprites+4]
    mov cx,28
    mov dx,22
    call draw_sprite
    mov cx,268
    call draw_sprite
    mov si,menu_txt_caught
    mov dh,8
    mov bl,11
    call print_str_center
    mov al,11
    jmp menu_end_panel
menu_end_time:
    mov si,banner_timeup   ; time ran out
    mov cx,(320-BANNER_TIMEUP_W)/2
    mov dx,24
    call draw_bitmap
    mov si,sprite_gauntlet
    mov cx,28
    mov dx,22
    call draw_sprite
    mov cx,268
    call draw_sprite
    mov si,menu_txt_over
    mov dh,8
    mov bl,10
    call print_str_center
    mov al,7
menu_end_panel:
    mov cx,80
    mov dx,80
    mov si,160
    mov di,44
    call menu_box
    mov si,menu_txt_final
    mov dh,11
    mov bl,6
    call print_str_center
    mov ax,[score]
    mov dh,13
    mov dl,17
    mov bl,10
    call print_num
    mov si,menu_txt_again
    mov dh,20
    mov bl,10
    call print_str_center
    mov si,menu_txt_quit
    mov dh,22
    mov bl,23
    call print_str_center
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

menu_txt_ctrl:   db 'LEFT / RIGHT ARROWS : MOVE',0
menu_txt_catch:  db 'CATCH THESE',0
menu_txt_avoid:  db 'AVOID!',0
menu_txt_pts5:   db 'REACTOR  +5',0
menu_txt_pts10:  db 'SHIELD  +10',0
menu_txt_pts15:  db 'MJOLNIR  +15',0
menu_txt_any:    db 'ANY STONE',0
menu_txt_ends:   db 'ENDS THE GAME',0
menu_txt_round:  db 'ROUND LASTS 2 MINUTES',0
menu_txt_press:  db 'PRESS ENTER TO START',0
menu_txt_caught: db 'YOU CAUGHT AN INFINITY STONE',0
menu_txt_over:   db 'THE ROUND IS OVER',0
menu_txt_final:  db 'FINAL SCORE',0
menu_txt_again:  db 'PRESS ENTER TO PLAY AGAIN',0
menu_txt_quit:   db 'ESC = QUIT',0

menu_stone_pos:
    dw 200,80, 232,80, 264,80
    dw 200,108, 232,108, 264,108

menu_bg_table:
    dw 12,12,1,1,6         ; stars
    dw 40,34,1,1,6
    dw 300,16,2,2,6
    dw 284,42,1,1,6
    dw 160,50,1,1,6
    dw 6,70,1,1,6
    dw 310,90,1,1,6
    dw 8,150,2,2,6
    dw 312,140,1,1,6
    dw 100,56,1,1,6
    dw 240,52,1,1,6
    dw 0,190,320,2,27      ; lava strip
    dw 0,192,320,4,3
    dw 0,196,320,4,4
    dw 20,190,10,1,3
    dw 90,191,14,1,3
    dw 170,190,12,1,3
    dw 250,191,12,1,3
    dw 0xFFFF
