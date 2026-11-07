[org 0x0100]
jmp start

end_reason db 0
score dw 0
ROUND_SECONDS equ 10
seconds_left db 120
tick_acc dw 0
GAUNTLET_Y equ 152
gauntlet_x dw 148
bg_seg dw 0
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
    call font_init
    mov ax,cs
    add ax,0x1000
    mov [bg_seg],ax        ; hidden background copy lives here
    call set_palette
    call install_isrs
    call draw_start_menu
	
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
    call draw_play_screen
	call start_round
	jmp main_loop

do_play:
    call update_timer
    cmp byte [state],STATE_PLAY    ; the timer may have ended the game
    jne main_loop
    cmp byte [key_enter],0
    je main_loop
    mov byte [key_enter],0
    mov byte [state],STATE_ENDED
    call draw_end_menu
    jmp main_loop

do_ended:
    cmp byte [key_enter],0
    je main_loop
    mov byte [key_enter],0
    mov byte [state],STATE_PLAY
    call draw_play_screen
	call start_round
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
    db 63,50,10     ; 27 bright lava
    db 36,8,2       ; 28 deep red
    db 18,24,52     ; 29 sky 1
    db 26,32,60     ; 30 sky 2
    db 34,42,63     ; 31 sky 3
    db 44,52,63     ; 32 sky 4
    db 63,52,48     ; 33 horizon glow
    db 60,62,63     ; 34 cloud
    db 48,54,63     ; 35 cloud shade
    db 30,48,63     ; 36 space light
    db 63,62,30     ; 37 mind light
    db 63,38,38     ; 38 reality light
    db 54,40,63     ; 39 power light
    db 30,63,38     ; 40 time light
    db 63,50,24     ; 41 soul light
    db 8,16,40      ; 42 space dark
    db 46,38,0      ; 43 mind dark
    db 38,6,6       ; 44 reality dark
    db 24,8,42      ; 45 power dark
    db 2,32,8       ; 46 time dark
    db 42,20,0      ; 47 soul dark
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
    push es
    mov ax,[bg_seg]
    mov es,ax              ; draw into the hidden copy
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
    mov dx,192
    mov di,8
    mov al,COL_GROUND
    call fill_rect         ; ground
    call draw_decor
    pop es
    call show_background   ; copy it to the screen
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
	
; copies the hidden background to the screen
show_background:
    push ax
    push cx
    push si
    push di
    push ds
    push es
    mov ax,0xA000
    mov es,ax
    mov ax,[bg_seg]
    mov ds,ax
    xor si,si
    xor di,di
    mov cx,32000
    cld
    rep movsw
    pop es
    pop ds
    pop di
    pop si
    pop cx
    pop ax
    ret

; CX=x, DX=y. Restores the 24x24 area from the hidden background
erase_sprite:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    push es
    push cx
    mov di,dx
    mov cl,8
    shl di,cl
    mov cl,6
    shl dx,cl
    add di,dx
    pop cx
    add di,cx              ; DI = y*320+x
    mov si,di
    mov ax,0xA000
    mov es,ax
    mov ax,[bg_seg]
    mov ds,ax
    cld
    mov bx,24
erase_row:
    mov cx,12              ; 24 bytes = 12 words
    push si
    push di
    rep movsw
    pop di
    pop si
    add si,320
    add di,320
    dec bx
    jnz erase_row
    pop es
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
	
draw_gauntlet:
    push cx
    push dx
    push si
    mov si,sprite_gauntlet
    mov cx,[gauntlet_x]
    mov dx,GAUNTLET_Y
    call draw_sprite
    pop si
    pop dx
    pop cx
    ret

draw_play_screen:
    call draw_background
    call draw_gauntlet
    mov si,sprite_arc          ; 5 points
    mov cx,40
    mov dx,40
    call draw_sprite
    mov si,sprite_shield       ; 10 points
    mov cx,140
    mov dx,70
    call draw_sprite
    mov si,sprite_mjolnir      ; 15 points
    mov cx,230
    mov dx,50
    call draw_sprite
	mov si,[stone_sprites]     ; Space stone
    mov cx,80
    mov dx,100
    call draw_sprite
    mov si,[stone_sprites+6]   ; Power stone
    mov cx,190
    mov dx,110
    call draw_sprite
    mov si,[stone_sprites+8]   ; Time stone
    mov cx,265
    mov dx,115
    call draw_sprite
    ret	

; draws every rectangle in decor_table (x, y, width, height, colour)
draw_decor:
    mov bx,decor_table
decor_loop:
    mov cx,[bx]
    cmp cx,0xFFFF          ; end marker
    je decor_done
    mov dx,[bx+2]
    mov si,[bx+4]
    mov di,[bx+6]
    mov ax,[bx+8]          ; colour ends up in AL
    call fill_rect
    add bx,10
    jmp decor_loop
decor_done:
    ret

decor_table:
    dw 0,10,320,30,29      ; sky bands, dark at the top
    dw 0,40,320,40,30
    dw 0,80,320,40,31
    dw 0,120,320,30,32
    dw 0,150,320,26,33     ; warm glow above the lava
    dw 22,16,1,1,6         ; stars
    dw 70,24,1,1,6
    dw 118,14,2,2,6
    dw 165,28,1,1,6
    dw 214,18,1,1,6
    dw 262,26,2,2,6
    dw 296,14,1,1,6
    dw 44,50,1,1,6
    dw 150,56,1,1,6
    dw 300,60,1,1,6
    dw 30,96,22,3,34       ; clouds
    dw 24,99,34,4,34
    dw 30,103,24,2,35
    dw 200,112,26,3,34
    dw 194,115,38,4,34
    dw 200,119,28,2,35
    dw 100,128,18,3,34
    dw 95,131,28,3,34
    dw 100,134,18,2,35
    dw 0,176,320,2,27      ; lava
    dw 0,178,320,4,3
    dw 0,182,320,6,4
    dw 0,188,320,4,28
    dw 14,176,10,1,3
    dw 60,177,12,1,3
    dw 105,176,9,1,3
    dw 150,177,14,1,3
    dw 200,176,10,1,3
    dw 245,177,12,1,3
    dw 290,176,10,1,3
    dw 30,180,16,1,27
    dw 120,181,20,1,27
    dw 215,180,18,1,27
    dw 270,181,14,1,27
    dw 70,185,12,1,3
    dw 170,186,16,1,3
    dw 250,185,10,1,3
    dw 45,189,2,2,3
    dw 130,190,2,2,3
    dw 225,189,2,2,3
    dw 0,192,320,1,23      ; ground
    dw 0,196,320,1,24
    dw 0xFFFF
	
	; sets the clock back to 2:00 and shows it
start_round:
    mov word [score],0
    mov byte [end_reason],0
    mov byte [seconds_left],ROUND_SECONDS
    mov word [tick_acc],0
    call draw_score
    call draw_time
    ret

; called once per game step. 10 per tick, 182 = one second (18.2 ticks/s)
update_timer:
    add word [tick_acc],10
    cmp word [tick_acc],182
    jb timer_done
    sub word [tick_acc],182
    dec byte [seconds_left]
    call draw_time
    cmp byte [seconds_left],0
    jne timer_done
    mov byte [state],STATE_ENDED   ; time's up
    call draw_end_menu
timer_done:
    ret

; draws TIME mm:ss in the top-left of the HUD
draw_time:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    xor cx,cx
    xor dx,dx
    mov si,88
    mov di,9
    mov al,COL_HUD
    call fill_rect         ; clear the old time
    mov byte [put_col],0   ; start at the left edge
    mov si,time_label
    call put_str
    mov al,[seconds_left]
    xor ah,ah
    mov bl,60
    div bl                 ; AL = minutes, AH = seconds
    push ax
    call put_two
    mov al,':'
    call put_char
    pop ax
    mov al,ah
    call put_two
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

put_str:                   ; SI = zero-terminated text
    lodsb
    cmp al,0
    je put_str_done
    call put_char
    jmp put_str
put_str_done:
    ret

put_two:                   ; AL = 0..99, printed as two digits
    xor ah,ah
    mov bl,10
    div bl
    push ax
    add al,'0'
    call put_char
    pop ax
    mov al,ah
    add al,'0'
    call put_char
    ret

put_char:                  ; AL = character, drawn in the HUD at the next column
    push bx
    push dx
    mov dh,0
    mov dl,[put_col]
    mov bl,COL_WHITE
    call draw_char
    inc byte [put_col]
    pop dx
    pop bx
    ret

time_label db 'TIME ',0
	
%include "gear.asm"
%include "stones.asm"
%include "text.asm"
%include "font.asm"
%include "screens.asm"
%include "menus.asm"
%include "banners.asm"