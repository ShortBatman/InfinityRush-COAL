; ============================================================
; text.asm  -  text helpers for Infinity Rush (task M1)
; Included at the bottom of infinity.asm (no org, no entry point).
; Uses BIOS int 10h in mode 13h (text grid 40 columns x 25 rows).
; Assumes DS = CS (so our data can be read/written) and ES = A000h.
; All registers are preserved by every routine.
; ============================================================


; ------------------------------------------------------------
; print_str
;   In:  SI = address of zero-terminated string
;        DH = text row, DL = text column, BL = colour
;   Stops early if the column would go past 39 (no wrapping).
; ------------------------------------------------------------
print_str:
    push ax
    push bx
    push dx
    push si

    mov bh, 0               ; video page 0
    mov ah, 02h             ; set cursor position (uses BH, DH, DL)
    int 10h

print_str_loop:
    cmp dl, 40              ; column 40 would wrap to next row
    jae print_str_done
    lodsb                   ; AL = next char, SI = SI + 1
    cmp al, 0               ; zero terminator?
    je print_str_done
    mov ah, 0Eh             ; teletype: print AL, colour in BL
    int 10h
    inc dl                  ; remember the column we are at
    jmp print_str_loop

print_str_done:
    pop si
    pop dx
    pop bx
    pop ax
    ret


; ------------------------------------------------------------
; print_num
;   In:  AX = unsigned number 0..65535
;        DH = row, DL = column, BL = colour
;   Prints the number right-aligned in a field of 5 characters.
;   (Make sure DL + 5 <= 40, i.e. DL <= 35.)
; ------------------------------------------------------------
print_num:
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    push dx                 ; extra copy of row/column (DIV will destroy DX)

    ; fill the 5-character buffer with spaces
    mov byte [print_num_buf],   ' '
    mov byte [print_num_buf+1], ' '
    mov byte [print_num_buf+2], ' '
    mov byte [print_num_buf+3], ' '
    mov byte [print_num_buf+4], ' '

    mov di, print_num_buf + 4   ; start at the last (rightmost) cell
    mov cx, 10                  ; divisor

print_num_digit:
    xor dx, dx              ; DX:AX = number (high word 0)
    div cx                  ; AX = AX / 10, DX = remainder (0..9)
    add dl, '0'             ; remainder -> ASCII digit
    mov [di], dl            ; store digit
    dec di                  ; move one cell to the left
    cmp ax, 0
    jne print_num_digit     ; loop until nothing is left (0 prints "0")

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
