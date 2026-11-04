[org 0x0100]
jmp start

STATE_START equ 0
STATE_PLAY  equ 1
STATE_ENDED equ 2
COL_BLACK  equ 0
COL_HUD    equ 1
COL_SKY    equ 2
COL_LAVA   equ 3
COL_LAVA2  equ 4
COL_GROUND equ 5
COL_WHITE  equ 6
spr_x   dw 0
spr_col db 0
state     db STATE_START
tick      dw 0
key_left  db 0
key_right db 0
key_enter db 0
key_esc   db 0
old8      dd 0
old9      dd 0


start:
    mov ax,0x0013          ; VGA 320x200, 256 colours
    int 0x10
    mov ax,0xA000
    mov es,ax              ; ES = video memory
    call set_palette
    call install_isrs
    mov al,1               ; navy = start screen
    call fill_screen
	
main_loop:
    call wait_tick
    cmp byte [key_esc],0
    jne exit
    cmp byte [state],STATE_START
    je do_start
    cmp byte [state],STATE_PLAY
    je do_play
    jmp do_ended

do_start:
    cmp byte [key_enter],0
    je main_loop
    mov byte [key_enter],0
    mov byte [state],STATE_PLAY
    call draw_background
	call draw_test_sprites
	jmp main_loop

do_play:
    cmp byte [key_enter],0
    je main_loop
    mov byte [key_enter],0
    mov byte [state],STATE_ENDED
    mov al,4               ; red = end screen
    call fill_screen
    jmp main_loop

do_ended:
    cmp byte [key_enter],0
    je main_loop
    mov byte [key_enter],0
    mov byte [state],STATE_PLAY
    call draw_background
    jmp main_loop

fill_screen:               ; AL = colour
    xor di,di
    mov ah,al
    mov cx,32000
    cld
    rep stosw
    ret

exit:
    call restore_isrs
    mov ax,0x0003          ; back to text mode
    int 10h
    mov ax,0x4C00
    int 21h

wait_tick:
    mov ax,[tick]
wait_loop:
    cmp ax,[tick]
    je wait_loop
    ret
	
	install_isrs:
    push es
    xor ax,ax
    mov es,ax              ; ES = interrupt vector table
    cli
    mov ax,[es:8*4]
    mov [old8],ax
    mov ax,[es:8*4+2]
    mov [old8+2],ax
    mov ax,[es:9*4]
    mov [old9],ax
    mov ax,[es:9*4+2]
    mov [old9+2],ax
    mov word [es:8*4],isr_timer
    mov [es:8*4+2],cs
    mov word [es:9*4],isr_keyboard
    mov [es:9*4+2],cs
    sti
    pop es
    ret

restore_isrs:
    push es
    xor ax,ax
    mov es,ax
    cli
    mov ax,[old8]
    mov [es:8*4],ax
    mov ax,[old8+2]
    mov [es:8*4+2],ax
    mov ax,[old9]
    mov [es:9*4],ax
    mov ax,[old9+2]
    mov [es:9*4+2],ax
    sti
    pop es
    ret

isr_timer:
    inc word [cs:tick]
    jmp far [cs:old8]

isr_keyboard:
    push ax
    in al,0x60             ; scancode
    mov ah,1
    test al,0x80           ; bit 7 set = key released
    jz key_pressed
    xor ah,ah
key_pressed:
    and al,0x7F
    cmp al,0x4B            ; Left
    jne skip_left
    mov [cs:key_left],ah
skip_left:
    cmp al,0x4D            ; Right
    jne skip_right
    mov [cs:key_right],ah
skip_right:
    cmp al,0x1C            ; Enter
    jne skip_enter
    mov [cs:key_enter],ah
skip_enter:
    cmp al,0x01            ; Esc
    jne skip_esc
    mov [cs:key_esc],ah
skip_esc:
    in al,0x61             ; acknowledge keyboard
    mov ah,al
    or al,0x80
    out 0x61,al
    mov al,ah
    out 0x61,al
    mov al,0x20            ; end of interrupt
    out 0x20,al
    pop ax
    iret
	
	set_palette:
    mov dx,0x3C8
    xor al,al
    out dx,al              ; start at colour 0
    inc dx                 ; DX = 0x3C9
    mov si,palette_data
    mov cx,PALETTE_BYTES
palette_loop:
    lodsb
    out dx,al
    loop palette_loop
    ret

; one line per colour: red, green, blue (each 0-63)
palette_data:
    db 0,0,0        ; 0  black (transparent in sprites)
    db 6,6,16       ; 1  HUD navy
    db 31,41,63     ; 2  sky
    db 60,25,5      ; 3  lava
    db 48,16,3      ; 4  dark lava
    db 26,28,32     ; 5  ground
    db 63,63,63     ; 6  white
    db 60,46,0      ; 7  gold
    db 46,30,6      ; 8  dark gold
    db 15,30,60     ; 9  blue
    db 63,56,5      ; 10 yellow
    db 60,16,16     ; 11 red
    db 8,52,60      ; 12 cyan
    db 55,10,10     ; 13 shield red
    db 9,25,60      ; 14 shield blue
    db 40,42,46     ; 15 grey
    db 36,16,2      ; 16 brown
    db 42,20,62     ; 17 purple
    db 8,50,16      ; 18 green
    db 62,36,4      ; 19 orange
	db 10,8,14      ; 20 outline
    db 63,58,25     ; 21 light gold
    db 35,60,63     ; 22 light cyan
    db 52,54,58     ; 23 light grey
    db 24,26,30     ; 24 dark grey
    db 46,26,8      ; 25 light brown
    db 63,34,34     ; 26 light red
PALETTE_BYTES equ $-palette_data

; CX=x, DX=y, SI=width, DI=height, AL=colour
fill_rect:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    mov bx,di              ; BX = rows left
    mov ah,al              ; park the colour in AH
    push cx                ; save x
    mov di,dx
    mov cl,8
    shl di,cl              ; y*256
    mov cl,6
    shl dx,cl              ; y*64
    add di,dx              ; y*320
    pop cx
    add di,cx              ; + x
    mov al,ah
    mov dx,si              ; DX = width
    cld
fill_row:
    mov cx,dx
    push di
    rep stosb
    pop di
    add di,320             ; next row
    dec bx
    jnz fill_row
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
	
draw_background:
    xor cx,cx
    xor dx,dx
    mov si,320
    mov di,10
    mov al,COL_HUD
    call fill_rect         ; HUD bar
    mov dx,9
    mov di,1
    mov al,COL_WHITE
    call fill_rect         ; divider line
    mov dx,10
    mov di,166
    mov al,COL_SKY
    call fill_rect         ; sky
    mov dx,176
    mov di,16
    mov al,COL_LAVA
    call fill_rect         ; lava
    mov dx,192
    mov di,8
    mov al,COL_GROUND
    call fill_rect         ; ground
    ret
	
	; SI=sprite (9 bytes), CX=x, DX=y. Colour 0 = transparent
; SI=sprite (24x24 bytes), CX=x, DX=y. Colour 0 = transparent
draw_sprite:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push cx                ; save x
    mov di,dx
    mov cl,8
    shl di,cl              ; y*256
    mov cl,6
    shl dx,cl              ; y*64
    add di,dx              ; y*320
    pop cx
    add di,cx              ; + x
    cld
    mov bx,24              ; 24 rows
sprite_row:
    push di
    mov cx,24              ; 24 pixels per row
sprite_px:
    lodsb
    cmp al,0
    je sprite_next         ; transparent, skip
    mov [es:di],al
sprite_next:
    inc di
    loop sprite_px
    pop di
    add di,320             ; next screen row
    dec bx
    jnz sprite_row
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
	
erase_sprite:
    push ax
    push si
    push di
    mov si,24
    mov di,24
    mov al,COL_SKY
    call fill_rect
    pop di
    pop si
    pop ax
    ret
	
	draw_test_sprites:
    mov si,sprite_gauntlet
    mov cx,40
    mov dx,152
    call draw_sprite
    mov si,sprite_arc
    mov cx,110
    call draw_sprite
    mov si,sprite_shield
    mov cx,180
    call draw_sprite
    mov si,sprite_mjolnir
    mov cx,250
    call draw_sprite
    ret
	
	%include "gear.asm"