[org 0x0100]
jmp start

STATE_START equ 0
STATE_PLAY  equ 1
STATE_ENDED equ 2

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
    call install_isrs
    mov al,1               ; blue = start screen
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
    mov al,2               ; green = play screen
    call fill_screen
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
    mov al,2
    call fill_screen
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