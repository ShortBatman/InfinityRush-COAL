; task M1

print_str:                  ; SI = string, DH = row, DL = column, BL = colour
    push ax
    push dx
    push si
print_str_loop:
    cmp dl, 40
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
    mov [di], dl            
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

print_num_buf:  db '     ', 0     


print_str_center:
    push ax
    push dx
    push di

    mov di, si            
    xor ax, ax            

print_str_center_len:
    cmp byte [di], 0
    je print_str_center_calc
    inc di
    inc ax
    jmp print_str_center_len

print_str_center_calc:
    cmp ax, 40
    jb print_str_center_fits
    mov dl, 0              
    jmp print_str_center_go

print_str_center_fits:
    mov dl, 40
    sub dl, al           
    shr dl, 1             

print_str_center_go:
    call print_str          

    pop di
    pop dx
    pop ax
    ret
