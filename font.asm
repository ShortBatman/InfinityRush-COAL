; font.asm - draws text pixel by pixel, so letters have no black box behind them

; gets the address of the BIOS 8x8 font (characters 0-127). call once at startup, after ES = A000h
font_init:
    push ax
    push bx
    push cx
    push dx
    push bp
    push es
    mov ax,0x1130
    mov bh,3
    int 0x10               ; returns ES:BP = address of the 8x8 font
    mov [font_off],bp
    mov ax,es
    mov [font_seg],ax
    pop es
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; AL = character (0-127), DH = text row, DL = text column, BL = colour. Draws only the letter's pixels
draw_char:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    mov bh,al              ; keep the character in BH
    mov al,dh
    xor ah,ah
    mov cx,2560            ; 8 pixel rows * 320
    push dx
    mul cx                 ; AX = row * 2560
    pop dx
    mov di,ax
    mov al,dl
    xor ah,ah
    mov cl,3
    shl ax,cl              ; column * 8
    add di,ax              ; DI = screen offset of the top-left pixel
    mov al,bh
    xor ah,ah
    mov cl,3
    shl ax,cl              ; character * 8 bytes
    add ax,[font_off]
    mov si,ax              ; SI = this character in the font
    mov ax,[font_seg]
    mov ds,ax              ; DS = font segment (no variables until we restore DS)
    mov ch,8               ; 8 rows
    cld
char_row:
    lodsb                  ; one row of the letter, 8 bits
    mov bh,al
    mov cl,8
char_bit:
    shl bh,1               ; leftmost bit goes into carry
    jnc char_skip
    mov [es:di],bl         ; bit is set: plot the pixel
char_skip:
    inc di
    dec cl
    jnz char_bit
    add di,312             ; back to the start of the next row (320 - 8)
    dec ch
    jnz char_row
    pop ds
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

font_off dw 0
font_seg dw 0
put_col  db 0
