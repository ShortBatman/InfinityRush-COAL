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
state     db STATE_START
tick      dw 0
key_left  db 0
key_right db 0
key_enter db 0
key_esc   db 0
old8      dd 0
old9      dd 0


start:
    mov ax,0x0013          
    int 0x10				;calls the IVT and AH=00 is to select "set video mode" and AL=13 means VGA 320x200, 256 colours
    mov ax,0xA000			; address of vga memory like 0xb800 is for display memory
    mov es,ax              ; ES = video memory
    call font_init			; in fonts.asm
    mov ax,cs
    add ax,0x1000			; a 64kb segment is reserved at the top and will be represented by bg_seg
    mov [bg_seg],ax        ; hidden background copy lives here
    call set_palette
    call install_isrs
    call draw_start_menu	;draws the start menu and enters the infinite main_loop

	
	
main_loop:
    call wait_tick
    cmp byte [key_esc],0		;key_esc is 0 until Escape is pressed
    jne exit
    cmp byte [state],STATE_START	;both state_start and state_play have been assigned values
    je do_start						;to which state the game is supposed to jump to, depends on the state variable
    cmp byte [state],STATE_PLAY
    je do_play
    jmp do_ended					; if state isnt start(0) or play(1) it must be end(2)
do_start:
    cmp byte [key_enter],0
    je main_loop				;if enter has not been pressed,remain in the main_loop
    mov byte [key_enter],0
    mov byte [state],STATE_PLAY		;if we are here, that means enter has been pressed and we enter the play state.
    call draw_play_screen			;draws the play screen lava etc
	call start_round				;resets timer and score
	jmp main_loop					;back to the main loop awaiting for further instructions
									;and this time we will enter play state cus state has been changed to 1
do_play:
    call update_timer				;sets the state to 2(end) when timer hits 0
    cmp byte [state],STATE_PLAY    ;the timer may have ended the game
    jne main_loop					;if state is still play then we continue wrna go back to main
    cmp byte [key_enter],0			;this is testing. we are jumping to main when enter isnt pressed. but after phase 2
    je main_loop					;this will be replaced with game logic. so rn when we press enter we go to end state	
    mov byte [key_enter],0
    mov byte [state],STATE_ENDED
    call draw_end_menu
    jmp main_loop
do_ended:
    cmp byte [key_enter],0
    je main_loop
    mov byte [key_enter],0			;if enter is pressed then we go back to play state
    mov byte [state],STATE_PLAY
    call draw_play_screen
	call start_round
    jmp main_loop



fill_screen:               ; AL = colour
    xor di,di
    mov ah,al				; Ah and Al both have the same color now. so the screen is filled with the same color
    mov cx,32000			;320 × 200 = 64,000 px
    cld						;64,000 ÷ 2 = 32,000 cells for stosw
    rep stosw
    ret

exit:
    call restore_isrs
    mov ax,0x0003          ;back to text mode from video mode
    int 10h					;reset the 0x0013 we did at the start
    mov ax,0x4c00
    int 21h

	;this loop is necessary to maintain a uniform speed of updates. wrna cpu unlimited speed k sath apni mrzi sy screen update krta jaega
wait_tick:
    mov ax,[tick]
wait_loop:
    cmp ax,[tick]		;tick will change when the timer int fires (in isr_timer). Until then, it is in a loop
    je wait_loop		;a tick is fired (tick is inc) 1/18.2 of a second automatically by INT 8
    ret
	
install_isrs:				;hooking interrupts
    push es
    xor ax,ax
    mov es,ax               ;ES = interrupt vector table
    cli						;no interrupts will fire till we're done hooking em 
    mov ax,[es:8*4]			
    mov [old8],ax
    mov ax,[es:8*4+2]		;saving old ints
    mov [old8+2],ax
    mov ax,[es:9*4]
    mov [old9],ax
    mov ax,[es:9*4+2]
    mov [old9+2],ax
    mov word [es:8*4],isr_timer			;pushing our ints in their place
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
    inc word [cs:tick]		;increments the tick variable each time INT 8(timer) is fired. cs seg cus it is a variable in our code segment
    jmp far [cs:old8]		; we use far bcs we are moving bw segments, back to the original old timer interrupt

isr_keyboard:
    push ax
    in al,0x60             ; scancode. al now has the key pressed (e.g: 4Bh)
    mov ah,1				; assume key is pressed
    test al,0x80           ; when the key is released, bit 7 is set of the same number.
    jz key_pressed			; if al = 0x80, yaani bit 7 is set. then keep ah = 1 
    xor ah,ah				; otherwise ah = 0, not pressed at all 
key_pressed:
    and al,0x7F				;clears bit 7 
    cmp al,0x4B            ; Left
    jne skip_left			;if the key in al is left key, then move whatever ah is in key_left (0 if not pressed, 1 if pressed)
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
    mov ah,al				;copy the original 0x61 into ah
    or al,0x80				; setting the bit 7
    out 0x61,al				; setting the bit 7 in the 0x61 tells the keyboard controller k han hum ny key receive kr li hai
    mov al,ah
    out 0x61,al				; copying the original value back to 0x61 to tell the controller k ab aglay input k liye ready ho jao
    mov al,0x20            ; end of interrupt (same for every int)
    out 0x20,al
    pop ax
    iret
	
set_palette:
    mov dx,0x3C8
    xor al,al
    out dx,al              ; tells the port 3C9 to get ready im abt to give you colors starting from al(color # 0)
    inc dx                 ; dx = 0x3C9
    mov si,palette_data
    mov cx,PALETTE_BYTES
palette_loop:
    lodsb					;moves color si to al and si++
    out dx,al				;moves al to 3C9 (aka the palette data port)
    loop palette_loop
    ret

; one line per colour: red, green, blue (each 0-63)
palette_data:
	; R, G, B
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
    mov bx,di              ; bx now stores the no. of rows left
    mov ah,al              ; temporarily store the colour(al) in ah
    push cx                ; save x coordinate
    mov di,dx			   ; di has the y-coordinate
    mov cl,8
    shl di,cl              ; y*256
    mov cl,6
    shl dx,cl              ; y*64
    add di,dx              ; y*256 + y*64 = y*320
    pop cx
    add di,cx              ; (x,y) in VGA = y*320 + x
    mov al,ah				; color goes back in al
    mov dx,si              ; dx has the width
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
    mov es,ax              ; now everything we draw below goes to the hidden bg copy
    xor cx,cx
    xor dx,dx
    mov si,320				; setting the parameters up for fill_rect
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
    call draw_decor			;adds details to the basic rectangles we just drew
    pop es
    call show_background   ; copy it from the hidden bg to the screen
    ret
	

draw_sprite:	; same as fill rect
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
    add di,dx              ; y*64 + y*256 = y*320
    pop cx
    add di,cx              ; (x,y) = y*320 + x
    cld
    mov bx,24              ; 24 rows left
sprite_row:
    push di
    mov cx,24              ; 24 pixels per row
sprite_px:				;draws the sprite
    lodsb
    cmp al,0				;al = 0 means transparent color. so if it is transparent, we skip coloring and bg remains visible
    je sprite_next         ; transparent, skip
    mov [es:di],al			; if not transparent, color the pixel
sprite_next:
    inc di
    loop sprite_px			;loops till the row(24px) is complete
    pop di
    add di,320             ; on to the next row
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
    mov ax,0xA000		;screen ka segment
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
erase_sprite:	; will use it when the gauntlet moves in phase 2
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
    mov cx,[gauntlet_x]			; variable bcs gauntlet will move horizontally in phase 2
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
	;stone_sprites is an array with stone addresses stored in it
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
    mov dx,[bx+2]		; preparing parameters for fill_rect
    mov si,[bx+4]
    mov di,[bx+6]
    mov ax,[bx+8]          ; colour ends up in AL
    call fill_rect
    add bx,10				; next line in the decor_table
    jmp decor_loop
decor_done:
    ret

decor_table:
	;  x,y,width,height,color
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
    mov byte [end_reason],0		; end_reason is 0 when time up and 1 when catch a stone
    mov byte [seconds_left],ROUND_SECONDS
    mov word [tick_acc],0
    call draw_score
    call draw_time
    ret

; called once per game step. 10 per tick, 182 = one second (18.2 ticks/s)
update_timer:
    add word [tick_acc],10			;update timer runs about 18.2 times a second
    cmp word [tick_acc],182			;hence 10*18.2 = 182 in a second
    jb timer_done
    sub word [tick_acc],182
    dec byte [seconds_left]
    call draw_time					;redraws the clock
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
    xor cx,cx		;parameters for fill_rect
    xor dx,dx
    mov si,88
    mov di,9
    mov al,COL_HUD
    call fill_rect         ; clear the old time
    mov byte [put_col],0   	; put_col font.asm mein aik variable hai which rmmbrs which col to draw the next char in
    mov si,time_label		;time_label = "TIME "
    call put_str
    mov al,[seconds_left]
    xor ah,ah
    mov bl,60
    div bl                 ; this division results in al = mins, ah = secs. result in al, remainder in ah.
    push ax
    call put_two			;prints al(mins)
    mov al,':'
    call put_char
    pop ax
    mov al,ah
    call put_two			;prints al(secs)
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

put_str:                   ; SI = zero-terminated text
    lodsb
    cmp al,0				; will loading from si to al till al hits a 0 (null terminator)
    je put_str_done
    call put_char			;print char
    jmp put_str
put_str_done:
    ret

put_two:                   ; AL = 0..99, printed as two digits
    xor ah,ah
    mov bl,10				;this division results in al=1st digit and ah=2nd digit
    div bl					;e.g: 59/10 => remainder = 9(ah) and result = 5(al) 
    push ax
    add al,'0'				;to convert 5 into '5' we add '0' (int to string).
    call put_char
    pop ax
    mov al,ah
    add al,'0'
    call put_char
    ret

put_char:                  ; AL = character, drawn in the HUD at the next column
    push bx
    push dx
    mov dh,0				;text row
    mov dl,[put_col]		;text col
    mov bl,COL_WHITE		;text color
    call draw_char			;in font.asm
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