; This program reads 2 strings from the CLI arguments, and does a bitwise AND,
; as long as they only contain 1's and 0's.

    global _start

    section .text

printR8:                    ; Procedure that prints a byte stored at the location stored in R8

    mov rax, 1              ; Syscall: sys_write
    mov rdi, 1              ; File descriptor: stdout
    mov rsi, r8             ; Source: the address stored in R8
    mov rdx, 1              ; Length: 1
    syscall
    ret                     ; Pop the return pointer, jump to it

_start:

    pop rdx                 ; Pop the argument count to RDX
    cmp rdx, 3              ; If not 3 arguments (program name, arg1, arg2)...
    jne fail                ; exit with error

    mov rdx, [rsp+8]        ; Instead of popping and discarding first argument, use offset
    mov qword [arg1], rdx   ; Store the pointer to the first byte of first arg string
    mov rdx, [rsp+2*8]      ; Next pointer on stack is 8 bytes after the last one
    mov qword [arg2], rdx   ; Store the pointer to the first byte of second arg string

                            ; Prints 1 if both inputs are 1
                            ; But for fewer comparisons and jumps it works like this:
                            ; * If values are equal, prints the value directly
andChar:                    ; * Otherwise prints 0

    mov r8, zero            ; Load pointer to "0" into R8 as the default to print
    mov rcx, [arg1]         ; Load the pointer to the current char in 1st argument into RCX
    mov dl, [rcx]           ; Load the byte at that pointer into DL
    mov rcx, [arg2]         ; Load the pointer to the current char in 2st argument into RCX
    cmp dl, [rcx]           ; Compare DL with value of RCX (char from 2nd argument)
    cmove r8, [arg1]        ; If equal, load the pointer to the 1st arg char into R8
                            ; (CMOVE = Conditional MOV Equal)
    call printR8            ; Print the value at address in R8

    inc qword [arg1]        ; Shift the pointer to the next char in the 1st arg string
    mov rcx, [arg1]         ; Load that pointer into RCX
    cmp byte [rcx], 0       ; If its value is 0x0 ...
    je ok                   ; exit without error

    inc qword [arg2]        ; (same for arg2)
    mov rcx, [arg2]         ;
    cmp byte [rcx], 0       ;
    je ok                   ;

    jmp andChar             ; Repeat for next characters of arg1 and arg2

ok:                         ; Exit with code 0

    mov r8, newln           ; Load pointer to "\n" into R8
    call printR8            ; Print newline
    mov rax, 60             ; Syscall: sys_exit
    xor rdi, rdi            ; Exit code: 0
    syscall

fail:                       ; Exit with code 123

    mov rax, 60             ; Syscall: sys_exit
    mov rdi, 123            ; Exit code: 123
    syscall

section .bss

arg1:   resq 1              ; QWORDs to store the pointers of chars in each argument string
arg2:   resq 1              ; The argument strings are null-terminated

section .data

zero:   db    "0"           ; Predefined ASCII "0" to print conveniently
newln:  db    0xa           ; Predefined ASCII "\n" to print conveniently

