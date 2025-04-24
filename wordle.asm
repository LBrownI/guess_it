; The program picks a random number between 1 and 10 and lets the user guess until correct.

section .data
    prompt      db "Guess a number (1-10): ", 0
    prompt_len  equ $ - prompt

    low_msg     db "Too low!", 10       
    low_msg_len equ $ - low_msg

    high_msg    db "Too high!", 10
    high_msg_len equ $ - high_msg

    correct_msg db "Correct!", 10
    correct_msg_len equ $ - correct_msg

section .text
    global _start

_start:
    ; === 1) Seed and generate target number ===
    ; Read Time Stamp Counter into RDX:RAX
    rdtsc                ; EDX:EAX = timestamp counter

    mov ecx, 10          ; Queremos un número del 0 al 9
    xor edx, edx         ; Limpiamos EDX para la división
    div ecx              ; Divide EDX:EAX entre ECX → cociente en EAX, resto en EDX

    add edx, 1           ; Lo convertimos a rango 1–10

    ; Guardamos el número aleatorio en EBX para mostrarlo o usarlo
    mov ebx, edx           

game_loop:
    ; === 2) Prompt user ===
    mov     rax, 1             ; syscall: write
    mov     rdi, 1             ; stdout
    mov     rsi, prompt        ; address of prompt
    mov     rdx, prompt_len    ; length of prompt
    syscall

    ; === 3) Read user input ===
    sub rsp, 16
    mov rsi, rsp
    mov rax, 0           ; syscall: read
    mov rdi, 0           ; stdin
    mov rdx, 16          ; max bytes
    syscall

    ; === 4) Convert ASCII input to integer ===
    mov     rsi, rsp           ; pointer to input
    movzx   eax, byte [rsi]    ; first character
    cmp     al, '1'            ; check if starts with '1'
    jne     single_digit
    movzx   ecx, byte [rsi+1]  ; check second char
    cmp     cl, '0'
    jne     single_digit
    mov     edi, 10            ; input was "10"
    jmp     got_guess

single_digit:
    sub     eax, '0'           ; convert ASCII '1'..'9' to integer 1..9
    mov     edi, eax           ; store in EDI

got_guess:
    add     rsp, 16            ; restore stack pointer

    ; === 5) Compare and respond ===
    cmp     edi, ebx           ; compare guess (EDI) with target (EBX)
    je      correct            ; if equal, jump to correct
    jl      too_low            ; if guess < target
    ; else guess > target

too_high:
    mov     rax, 1
    mov     rdi, 1
    mov     rsi, high_msg
    mov     rdx, high_msg_len
    syscall
    jmp     game_loop

too_low:
    mov     rax, 1
    mov     rdi, 1
    mov     rsi, low_msg
    mov     rdx, low_msg_len
    syscall
    jmp     game_loop

correct:
    mov     rax, 1             ; write "Correct!" message
    mov     rdi, 1
    mov     rsi, correct_msg
    mov     rdx, correct_msg_len
    syscall

    ; === 6) Exit program ===
    mov     rax, 60            ; syscall: exit
    xor     rdi, rdi           ; exit code 0
    syscall
