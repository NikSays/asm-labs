; This program reads a file using C stdio.h

    global main             ; The resulting executable will run the C runtime, which will call main

    extern fopen            ; Include external labels from stdio
    extern fread
    extern fclose

section .text

main:
    sub rsp, 8              ; Align stack to 16 bytes

open:                       ; Open the file

    mov rdi, fname          ; 1st argument: filename
    mov rsi, fmode          ; 2nd argument: mode
    call fopen              ; Open file
    mov qword [fp], rax     ; Store the returned file pointer
    cmp rax, 0              ; If the file pointer is zero...
    je fail                 ; exit with error

read:                       ; Read a chunk of file

    mov rdi, str            ; 1st argument: pointer to buffer
    mov rsi, 1              ; 2nd argument: size of element to read
    mov rdx, 255            ; 3rd argument: number of elements to read
    mov rcx, [fp]           ; 4th argument: file pointer
    call fread              ; Read chunk
    mov byte [len], al      ; Returns number of fully-read elements. Store in len
                            ; (since each element is 1 byte, returns number of bytes read)
    cmp rax, 0              ; If read 0 bytes...
    je ok                   ; exit without error

print:                      ; Print the chunk

    mov rax, 1              ; Syscall: sys_write
    mov rdi, 1              ; File descriptor: stdout
    mov rsi, str            ; Source: the str buffer
    mov rdx, [len]          ; Length: value of len (number of bytes read)
    syscall                 ; Write to stdout
    jmp read                ; Read next chunk

ok:                         ; Return 0

    mov rdi, [fp]           ; 1st argument: file address to close
    call fclose             ; Close file
    add rsp, 8              ; Revert stack to the original state
    xor rax, rax            ; Empty rax
    ret                     ; Return from main




fail:                       ; Return 123

    add rsp, 8              ; Revert stack to the original state
    mov rax, 123            ; Set rax to 123
    ret                     ; Return from main

section .data

fname:   db "input.txt", 0  ; File to read. C string, null-terminated
fmode:   db "r", 0          ; File mode. r means read
len:     db 0               ; 1 byte to store the length of data in the str buffer

section .bss

fp:      resq 1             ; 1 qword (8 bytes) to store the file pointer
str:     resb 255           ; Buffer. Since len is 1 byte, len<=255, so the buffer is 255 bytes