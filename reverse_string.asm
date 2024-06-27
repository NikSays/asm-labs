; This program inverts a string of up to 16 characters read from STDIN.
;
; It starts with RCX storing the pointer to the end of a preallocated memory range, 
; then it calls sys_read, reads the character, stores it into the address in RCX. 
; If the input wasn't a newline, and the preallocated memory range isn't full, it 
; increments the length of the string, decrements RCX, so the next character is put
; before the others, and repeats the process. This process of storing and decrementing
; RCX, means that the sting will be stored in reverse order.
;
; If the buffer is full, and the last character we've read wasn't a newline, there can 
; still be more characters in the input. If they are not read, they may spill out, and 
; the shell will read them after the program exits. That's why there's a flush loop 
; that reads and discards every character from input until it hits a newline.
;
; After that, the program prints out the string starting with the address from RCX 
; (the last place we've put a character), then prints a newline, and exits.

    global _start

    section .text
_start:
    mov rcx, str+16     ; Save end-of-string pointer into counter

scan:                   ; Read 1 char from stdin
    push rcx            ; Push counter to stack, since syscall changes it
    mov rax, 0          ; Syscall: sys_read
    mov rdi, 0          ; File descriptor: stdin
    mov rsi, cur        ; Destination: cur (current char)
    mov rdx, 1          ; Length: 1
    syscall
    pop rcx             ; Pop to restore the counter

    cmp byte [cur], 10  ; If read newline -> don't save it, print the string
    je print

    cmp byte [len], 16  ; If buffer is full -> print the string
    je flush

    dec rcx             ; Decrement to counter to save the string in reverse
    inc byte [len]      ; Increment length

    mov al, [cur]       ; Load value of cur into AX (least byte of RAX)
    mov byte [rcx], al  ; Move the char from AX, into the address stored in RCX 
                        ; (not RCX itself)

    jmp scan            ; Continue reading

flush:                  ; Read and disregard all extra input until newline
    push rcx            ; ( same as the reading routine in scan )
    mov rax, 0
    mov rdi, 0
    mov rsi, cur
    mov rdx, 1
    syscall
    pop rcx

    cmp byte [cur], 10  ; If not newline -> repeat
    jne flush

print:                  ; Output the string
    mov rax, 1          ; Syscall: sys_write
    mov rdi, 1          ; File descriptor: stdout
    mov rsi, rcx        ; Source: the address stored in counter
    mov dl, [len]       ; Length: value of len
    syscall
                        ; Output a newline
    mov byte [cur], 10  ; Load \n into value of cur
    mov rax, 1          ; Syscall: sys_write
    mov rdi, 1          ; File descriptor: stdout
    mov rsi, cur        ; Source: cur (\n)
    mov rdx, 1          ; Length: 1
    syscall

    mov rax, 60         ; Syscall: sys_exit
    xor rdi, rdi        ; Empty rdi for exit code 0
    syscall

section .bss
str:    resb    16      ; 16 bytes for 16 chars to reverse
cur:    resb    1       ; 1 byte to hold the current char

section .data
len:    db  0           ; 1 byte initialized to 0 to store current length of the string