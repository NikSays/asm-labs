; This program showcases a selection of different subroutines.

    global main

    extern getchar
    extern srand
    extern time
    extern scanf
    extern printf
    extern rand

%define str_1_len 255  ; Preprocessor: Replace all instances of "str_1_len" with "255".

section        .text

; ===== procedure flushStdin ==================  ; Read and discard all characters from stdin until a newline.

flushStdin:
    sub    rsp, 8           ; Align stack.

flushStdin_loop:
    call    getchar         ; Read a character from stdin.
    cmp    eax, 10          ; If the character is not "\n",
    jnz    flushStdin_loop  ; repeat.

    add    rsp, 8           ; Reset stack.
    ret                     ; Return.


; ===== 0: procedure tenRandom ================  ; Print 10 random integers in [1; 55].
                                                 ; int32_1 - counter for successfully generated numbers.
tenRandom:                                       ; int8_1 - current random number.

    sub    rsp, 8                ; Align stack.
    mov    dword [int32_1], 0    ; Initialize counter.

tenRandom_loop:
    cmp    dword [int32_1], 10   ; If counter >= 10,
    jge    tenRandom_done        ; done.

    call    rand                 ; Generate a random number into RAX.
    mov    byte [int8_1], al     ; Put the result into a byte. This clamps it to [-128; 127].

    cmp    byte [int8_1], 0      ; If number <= 0,
    jle    tenRandom_loop        ; try again.
    cmp    byte [int8_1], 55     ; If number > 55,
    jg    tenRandom_loop         ; try again.

    add    dword [int32_1], 1    ; Increment counter.


    mov    rdi, print_int_fmt    ; 1st argument: format string "%d\n".
    movsx    rsi, byte [int8_1]  ; 2nd argument: the number to print.
                                 ; MOVSX puts the number into lowest byte of RSI, and fills everything else with 0.
    call    printf               ; Print the number.

    jmp    tenRandom_loop        ; Next iteration.

tenRandom_done:
    add    rsp, 8                ; Reset stack.
    ret                          ; Return.


; ===== 6: procedure lowercase ================  ; Convert string to lowercase.
                                                 ; str_1   - the string.
                                                 ; int8_1  - current character.
lowercase:                                       ; int32_1 - length of the string.

    sub    rsp, 8                      ; Align stack.

    mov    rdi, input_string_str       ; 1st argument: "Input char" string.
    call    printf                     ; Print the string.

    mov    rcx, str_1                  ; Save string pointer into counter.
    mov    [int32_1], dword 0          ; Initialize string length to 0.

lowercase_scan:                        ; Read 1 char from stdin to the string.
    push    rcx                        ; Push counter to stack, since syscall changes it.
    mov    rax, 0                      ; Syscall: sys_read.
    mov    rdi, 0                      ; File descriptor: stdin.
    mov    rsi, int8_1                 ; Destination: int8_1.
    mov    rdx, 1                      ; Length: 1.
    syscall
    pop    rcx                         ; Pop to restore the counter.

    mov    al, [int8_1]                ; Load the current char into AL (least byte of RAX).

    cmp    al, 10                      ; If read newline,
    je    lowercase_print              ; don't save it, print the string.

    cmp    dword [int32_1], str_1_len  ; If buffer is full,
    je    lowercase_flush              ; flush, then print the string.

                                       ; JA/JB (above/below) makes an unsigned comparison.
    cmp    al, 65                      ; If below 'A',
    jb    lowercase_store              ; store the character instantly.

    cmp    al, 90                      ; If above 'Z',
    ja    lowercase_store              ; store the character instantly.

    add    al, 32                      ; Else, add 32 to make lowercase, then store.

lowercase_store:
    mov    byte [rcx], al              ; Move the char from AL, into the address stored in RCX (not RCX itself).

    inc    rcx                         ; Increment to counter to save the next char later.
    inc    dword [int32_1]             ; Increment length.

    jmp    lowercase_scan              ; Continue reading.

lowercase_flush:
    call    flushStdin                 ; Read and disregard all extra input until newline.

lowercase_print:                       ; Output the string.
    mov    rax, 1                      ; Syscall: sys_write.
    mov    rdi, 1                      ; File descriptor: stdout.
    mov    rsi, str_1                  ; Source: str_1.
    mov    edx, [int32_1]              ; Length: value of int32_1.
    syscall

    mov    byte [int8_1], 10           ; Load \n into value of int8_1.
    mov    rax, 1                      ; Syscall: sys_write.
    mov    rdi, 1                      ; File descriptor: stdout.
    mov    rsi, int8_1                 ; Source: value of int8_1 (\n).
    mov    rdx, 1                      ; Length: 1.
    syscall                            ; Output a newline.

    add    rsp, 8                      ; Reset stack.
    ret                                ; Return.


; ===== 7: procedure strlen ===================  ; Calculate length of a string.
                                                 ; int8_1  - current character.
strlen:                                          ; int32_1 - length of the string.

    sub    rsp, 8                 ; Align stack.

    mov    rdi, input_string_str  ; 1st argument: "Input str" string.
    call    printf                ; Print the string.

    mov    [int32_1], dword 0     ; Initialize string length to 0.

strlen_scan:                      ; Read the char to be deleted.
    mov    rax, 0                 ; Syscall: sys_read.
    mov    rdi, 0                 ; File descriptor: stdin.
    mov    rsi, int8_1            ; Destination: int8_1.
    mov    rdx, 1                 ; Length: 1.
    syscall

    mov    al, [int8_1]           ; Load the current char into AL (least byte of RAX).

    cmp    al, 10                 ; If read newline,
    je    strlen_print            ; don't save it, print the length.

    inc    dword [int32_1]        ; Increment the length.
    jmp    strlen_scan            ; Continue reading.

strlen_print:                     ; Output the string.
    mov    rdi, print_int_fmt     ; 1st argument: format string "%d\n".
    mov    esi, dword [int32_1]   ; 2nd argument: number to print (length).
    call    printf                ; Print the number.

    add    rsp, 8                 ; Reset stack.
    ret                           ; Return.


; ===== 9: procedure reverse ==================  ; Invert a string.
                                                 ; str_1   - the string to reverse.
                                                 ; int8_1  - current character.
reverse:                                         ; int32_1 - length of the string.

    sub    rsp, 8                      ; Align stack.

    mov    rdi, input_string_str       ; 1st argument: "Input char" string.
    call    printf                     ; Print the string.

    mov    rcx, str_1+str_1_len        ; Save end-of-string pointer into counter.
    mov    [int32_1], dword 0          ; Initialize string length to 0.

reverse_scan:                          ; Read 1 char from stdin to the string.
    push    rcx                        ; Push counter to stack, since syscall changes it.
    mov    rax, 0                      ; Syscall: sys_read.
    mov    rdi, 0                      ; File descriptor: stdin.
    mov    rsi, int8_1                 ; Destination: int8_1.
    mov    rdx, 1                      ; Length: 1.
    syscall
    pop    rcx                         ; Pop to restore the counter.

    mov    al, [int8_1]                ; Load the current char into AL (least byte of RAX).

    cmp    byte [int8_1], 10           ; If read newline,
    je    reverse_print                ; don't save it, print the string.

    cmp    dword [int32_1], str_1_len  ; If buffer is full,
    je    reverse_flush                ; flush, then print the string.

    dec    rcx                         ; Decrement to counter to save the string in reverse.
    inc    dword [int32_1]             ; Increment length.
    mov    byte [rcx], al              ; Move the char from AL, into the address stored in RCX (not RCX itself).

    jmp    reverse_scan                ; Continue reading.

reverse_flush:
    call    flushStdin                 ; Read and disregard all extra input until newline.

reverse_print:                         ; Output the string.
    mov    rax, 1                      ; Syscall: sys_write.
    mov    rdi, 1                      ; File descriptor: stdout.
    mov    rsi, rcx                    ; Source: not start of the string, current value of the counter.
    mov    edx, [int32_1]              ; Length: value of int32_1.
    syscall

    mov    byte [int8_1], 10           ; Load \n into value of int8_1.
    mov    rax, 1                      ; Syscall: sys_write.
    mov    rdi, 1                      ; File descriptor: stdout.
    mov    rsi, int8_1                 ; Source: value of int8_1 (\n).
    mov    rdx, 1                      ; Length: 1.
    syscall                            ; Output a newline.

    add    rsp, 8                      ; Reset stack.
    ret                                ; Return.


; ===== 15: procedure dropChar ================  ; Remove a character from a string.
                                                 ; str_1   - the string.
                                                 ; int8_1  - character to delete.
                                                 ; int8_2  - current character of the string.
dropChar:                                        ; int32_1 - length of the string.

    sub    rsp, 8                      ; Align stack.

    mov    rdi, input_del_char_str     ; 1st argument: "Input char" string.
    call    printf                     ; Print the string.

dropChar_readChar:                     ; Read the char to be deleted.
    mov    rax, 0                      ; Syscall: sys_read.
    mov    rdi, 0                      ; File descriptor: stdin.
    mov    rsi, int8_1                 ; Destination: int8_1.
    mov    rdx, 1                      ; Length: 1.
    syscall

    call    flushStdin                 ; Read and disregard all extra input until newline.

    mov    rdi, input_string_str       ; 1st argument: "Input str" string.
    call    printf                     ; Print the string.

    mov    rcx, str_1                  ; Save string pointer into counter.
    mov    [int32_1], dword 0          ; Initialize string length to 0.

dropChar_scan:                         ; Read 1 char from stdin to the string.
    push    rcx                        ; Push counter to stack, since syscall changes it.
    mov    rax, 0                      ; Syscall: sys_read.
    mov    rdi, 0                      ; File descriptor: stdin.
    mov    rsi, int8_2                 ; Destination: int8_2.
    mov    rdx, 1                      ; Length: 1.
    syscall
    pop    rcx                         ; Pop to restore the counter.

    mov    al, [int8_2]                ; Load the current char into AL (least byte of RAX).

    cmp    al, 10                      ; If read newline,
    je    dropChar_print               ; don't save it, print the string.

    cmp    dword [int32_1], str_1_len  ; If buffer is full,
    je    dropChar_flush               ; flush, then print the string.

    cmp    al, [int8_1]                ; If read the deleted char,
    je    dropChar_scan                ; don't save it, read next char.

    mov    byte [rcx], al              ; Move the char from AL, into the address stored in RCX (not RCX itself).
    inc    rcx                         ; Increment to counter to save the next char later.
    inc    dword [int32_1]             ; Increment length.

    jmp    dropChar_scan               ; Continue reading.

dropChar_flush:
    call    flushStdin                 ; Read and disregard all extra input until newline.

dropChar_print:                        ; Output the string.
    mov    rax, 1                      ; Syscall: sys_write.
    mov    rdi, 1                      ; File descriptor: stdout.
    mov    rsi, str_1                  ; Source: str_1.
    mov    edx, [int32_1]              ; Length: value of int32_1.
    syscall

    mov    byte [int8_2], 10           ; Load \n into value of int8_2.
    mov    rax, 1                      ; Syscall: sys_write.
    mov    rdi, 1                      ; File descriptor: stdout.
    mov    rsi, int8_2                 ; Source: value of int8_2 (\n).
    mov    rdx, 1                      ; Length: 1.
    syscall                            ; Output a newline.

    add    rsp, 8                      ; Reset stack.
    ret                                ; Return.


; ===== 27: procedure add =====================  ; Add 2 numbers from stdin.
                                                 ; int32_1 - first number.
add:                                             ; int32_2 - second number.

    sub    rsp, 8                 ; Align stack.

    mov    rdi, input_2_ints_str  ; 1st argument: the "Input 2 numbers" message.
    call    printf                ; Print the message.

    mov    rdi, scan_2_ints_fmt   ; 1st argument: format string "%d %d".
    mov    rsi, int32_1           ; 2nd argument: pointer to 1st number.
    mov    rdx, int32_2           ; 3rd argument: pointer to 2nd number.
    call    scanf                 ; Read from stdin.

    mov    eax, dword [int32_1]   ; Move 1st number to EAX.
    mov    edx, dword [int32_2]   ; Move 2nd number to EDX.
    add    eax, edx               ; Add 2nd number to the 1st in EAX.

    mov    rdi, print_int_fmt     ; 1st argument: format string "%d\n".
    mov    esi, eax               ; 2nd argument: number to print.
    call    printf                ; Print the number.

    call    flushStdin            ; Discard all remaining input.

    add    rsp, 8                 ; Reset stack.
    ret                           ; Return.


; ===== 29: procedure multiply ================  ; Multiply 2 numbers from stdin.
                                                 ; int32_1 - first number.
multiply:                                        ; int32_2 - second number.

    sub    rsp, 8                 ; Align stack.

    mov    rdi, input_2_ints_str  ; 1st argument: the "Input 2 numbers" message.
    call    printf                ; Print the message.

    mov    rdi, scan_2_ints_fmt   ; 1st argument: format string "%d %d".
    mov    rsi, int32_1           ; 2nd argument: pointer to 1st number.
    mov    rdx, int32_2           ; 3rd argument: pointer to 2nd number.
    call    scanf                 ; Read from stdin.

    mov    edx, dword [int32_1]   ; Move 1st number to EAX.
    mov    eax, dword [int32_2]   ; Move 2nd number to EDX.
    imul    eax, edx              ; Multiply 2nd number by the 1st in EAX.

    mov    rdi, print_int_fmt     ; 1st argument: format string "%d\n".
    mov    esi, eax               ; 2nd argument: number to print.
    call    printf                ; Print the number.

    call    flushStdin            ; Discard all remaining input.

    add    rsp, 8                 ; Reset stack.
    ret                           ; Return.


; ===== 35: procedure oneRandom ===============  ; Print a random integer in [-128; 127].
oneRandom:
    sub    rsp, 8              ; Align stack.

    call    rand               ; Generate a random number into RAX.
    movsx    rsi, al           ; 2nd argument: lowest byte of the random number.
    mov    rdi, print_int_fmt  ; 1st argument: format string "%d\n".
    call    printf             ; Print the number.

    add    rsp, 8              ; Reset stack.
    ret                        ; Return.


; ===== main function =========================  ; Menu with task selection.
                                                 ; int8_1 - character selecting a task.
main:
    sub    rsp, 8                  ; Align stack.

    mov    edi, 0                  ; 1st argument: NULLPTR, requests current time.
    call    time                   ; Get time.

    mov    edi, eax                ; 1st argument: value returned by the time() call.
    call    srand                  ; Seed the random generator.

main_loop:
    mov    rdi, prompt_str         ; 1st argument: the prompt string.
    call    printf                 ; Print the prompt.

    call    getchar                ; Read a character.
    mov    byte [int8_1], al       ; Store the char.

    call    flushStdin             ; Discard all remaining input.

    mov    al, byte [int8_1]       ; Load the user input into AL (lowest byte of RAX).
    cmp    eax, '0'                ; If input is '0',
    je    main_0                   ; goto main_0.
    cmp    eax, '1'                ; Same for every task number.
    je    main_1
    cmp    eax, '2'
    je    main_2
    cmp    eax, '3'
    je    main_3
    cmp    eax, '4'
    je    main_4
    cmp    eax, '5'
    je    main_5
    cmp    eax, '6'
    je    main_6
    cmp    eax, '7'
    je    main_7
    jmp     main_invalid           ; If neither condition worked, handle invalid input.

main_0:    call    tenRandom       ; Call corresponding procedure.
    jmp    main_loop               ; Return to menu.
main_1:    call    strlen          ; Same for every task.
    jmp    main_loop
main_2:    call    lowercase
    jmp    main_loop
main_3: call    reverse
    jmp    main_loop
main_4:    call    dropChar
    jmp    main_loop
main_5:    call    add
    jmp    main_loop
main_6:    call    multiply
    jmp    main_loop
main_7:    call    oneRandom
    jmp    main_loop

main_invalid:
    mov    rdi, invalid_input_str  ; 1st argument: the "Invalid input" message.
    call    printf                 ; Print the message.
    jmp    main_loop               ; Return to menu.


section     .data  ; Predefined strings used in printf.

print_int_fmt:
    db "%d", 10, 0

scan_2_ints_fmt:
    db "%d %d", 0

scan_string_fmt:
    db "%s", 0

prompt_str:
    db 10, "=== MENU ===", 10
    db "0 - Generate 10 random numbers from 1 to 55.", 10
    db "1 - Calculate length of a sting.", 10
    db "2 - Transform string to lowercase.", 10
    db "3 - Invert a string.", 10
    db "4 - Remove a character from the string.", 10
    db "5 - Add 2 numbers.", 10
    db "6 - Multiply 2 numbers.", 10
    db "7 - Generate 1 random number.", 10
    db "Enter 0-7: ", 0

invalid_input_str:
    db "Invalid input.", 10, 0

input_2_ints_str:
    db "Input 2 numbers, separated by a space...", 10, 0

input_string_str:
    db "Input the string...", 10, 0

input_del_char_str:
    db "Input the character to delete...", 10, 0


section     .bss  ; Preallocated variables used in procedures.

int32_1:    resd 1
int32_2:    resd 1
int8_1:        resb 1
int8_2:        resb 1
str_1:        resb str_1_len