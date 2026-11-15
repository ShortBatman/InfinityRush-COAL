




print_str:                  ; SI = string, DH = row, DL = column, BL = colour
    push ax
    push dx
    push si
print_str_loop:
    cmp dl, 40					;dl = 40 means end of screen so we stop
    jae print_str_done
    lodsb
    cmp al, 0
    je print_str_done
    call draw_char          ; draws only the letter's pixels (see font.asm)
    inc dl
    jmp print_str_loop
print_str_done:
    pop si
    pop dx
    pop ax
    ret

; ax has the number that is to be printed
print_num:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    push dx                 

    ; fill 5 character buffer with spaces

    mov byte [print_num_buf],   ' '
    mov byte [print_num_buf+1], ' '
    mov byte [print_num_buf+2], ' '
    mov byte [print_num_buf+3], ' '
    mov byte [print_num_buf+4], ' '

    mov di, print_num_buf + 4   
    mov cx, 10                 

print_num_digit:
    xor dx, dx              
    div cx                 
    add dl, '0'            
    mov [di], dl   ;print_num_buf + di = '*the digit we just separated*'          
    dec di                  
    cmp ax, 0
    jne print_num_digit     

    pop dx                
    mov si, print_num_buf
    call print_str        

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

print_num_buf:  db '     ', 0     ; the buffer


print_str_center:
    push ax
    push dx
    push di

    mov di, si            ;now both di and si point to the start of the text
    xor ax, ax            

print_str_center_len:
    cmp byte [di], 0
    je print_str_center_calc
    inc di
    inc ax					;ax will store the length of the string
    jmp print_str_center_len

print_str_center_calc:
    cmp ax, 40
    jb print_str_center_fits
    mov dl, 0              		;if string size is bigger than the screen, yaani it cant fit in the centre.
    jmp print_str_center_go		;it'll simply print from the start of the row

print_str_center_fits:
    mov dl, 40					;dl=total cols on screen=40
    sub dl, al           		; dl = total - textlength	e.g: textlen is 20: dl=40-20=20
    shr dl, 1             		; dl = dl/2						 dl = dl/2 = 10
	; now dl points at the address which will centre align the text
print_str_center_go:
    call print_str          

    pop di
    pop dx
    pop ax
    ret
