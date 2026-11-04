; task M1

print_str:
    push ax
    push bx
    push dx
    push si

    mov bh, 0               
    mov ah, 02h             ;
    int 10h

print_str_loop:
    cmp dl, 40              
    jae print_str_done
    lodsb                 
    cmp al, 0               
    je print_str_done
    mov ah, 0Eh             
    int 10h
    inc dl                 
    jmp print_str_loop

print_str_done:
    pop si
    pop dx
    pop bx
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

    pop dx                  ; get row/column back
    mov si, print_num_buf
    call print_str          ; BL is still the colour

    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

print_num_buf:  db '     ', 0       ; 5 characters + terminator


; ------------------------------------------------------------
; print_str_center
;   In:  SI = zero-terminated string, DH = row, BL = colour
;   Column = (40 - length) / 2.  Strings of 40+ characters start at 0.
; ------------------------------------------------------------
print_str_center:
    push ax
    push dx
    push di

    mov di, si              ; DI walks the string, SI stays at its start
    xor ax, ax              ; AX = length counter

print_str_center_len:
    cmp byte [di], 0
    je print_str_center_calc
    inc di
    inc ax
    jmp print_str_center_len

print_str_center_calc:
    cmp ax, 40
    jb print_str_center_fits
    mov dl, 0               ; too long: start at column 0
    jmp print_str_center_go

print_str_center_fits:
    mov dl, 40
    sub dl, al              ; 40 - length
    shr dl, 1               ; divide by 2

print_str_center_go:
    call print_str          ; DH = row (unchanged), DL = column

    pop di
    pop dx
    pop ax
    ret
