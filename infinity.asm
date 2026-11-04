org 0x100
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