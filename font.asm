; gets the address of the BIOS 8x8 font (characters 0-127). call once at startup, after ES = A000h
font_init:
    push ax
    push bx
    push cx
    push dx
    push bp
    push es
    mov ax,0x1130		   ;ah=11 enters char generator mode and al=30 means get font information
    mov bh,3			   ;bh=3 picks 8x8 font table.
    int 0x10               ;moves address of the 8x8 font table into ES:BP
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

; al = character, dh = text row, dl = text column, bl = colour.
;Draws only the letter's pixels
draw_char:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ds
    mov bh,al              ; keep the character in bh cus al mul mein use ho gas
    mov al,dh
    xor ah,ah			   ; ax = row number
    mov cx,2560            ; 8 pixels in each rowcell * 320 cells = 2560 bytes in each row
    push dx
    mul cx                 ; ax = row(ax) * 2560(cx) = x in (x,y) of where the char is supposed to be printed
    pop dx
    mov di,ax				;di now has the offset of the row start
    mov al,dl
    xor ah,ah
    mov cl,3
    shl ax,cl              ; y in (x,y) = column(ax) * 8 = ax
    add di,ax              ; di is now at (x,y)
	
    mov al,bh
    xor ah,ah
    mov cl,3			   ;in font table, letter number e.g:65 starts at 65*8 byte. hence we shl 3 times
    shl ax,cl              ; ax = character * 8 bytes = location of the character bh in the font table
    add ax,[font_off]	   ;font_off is the address of the start of the font table
    mov si,ax              ; si now points at the location of the character bh in the font table
    mov ax,[font_seg]
    mov ds,ax              ; DS = font segment (no variables until we restore DS)
    mov ch,8               ; 8 rows to draw
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
