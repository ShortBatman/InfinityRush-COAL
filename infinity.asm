org [0x0100]
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