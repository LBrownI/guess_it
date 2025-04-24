; ========================= Data Section =========================
section .data
    prompt          db "Guess a number (1-10): ", 0
    prompt_len      equ $ - prompt

    low_msg         db "Too low!", 10
    low_msg_len     equ $ - low_msg

    high_msg        db "Too high!", 10
    high_msg_len    equ $ - high_msg

    correct_msg     db "Correct!", 10
    correct_msg_len equ $ - correct_msg

    invalid_msg     db "Invalid input! ", 10
    invalid_msg_len equ $ - invalid_msg

; ========================= Code Section =========================
section .text
    global _start                   ; Entry point

; ------------------------- Program Start -------------------------
_start:
    ; --- Generate Random Number (1-10) ---
    rdtsc                           ; Read CPU timestamp (pseudo-random seed) into EDX:EAX
    mov ecx, 10                     ; Divisor for modulo 10
    xor edx, edx                    ; Clear EDX for 32-bit division
    div ecx                         ; Divide EAX by 10. Remainder (0-9) is in EDX.
    add edx, 1                      ; Adjust range to 1-10
    mov ebx, edx                    ; Store target number in EBX

; ------------------------- Main Game Loop -------------------------
game_loop:
    ; --- Show Prompt ---
    mov rax, 1                      ; sys_write
    mov rdi, 1                      ; stdout
    mov rsi, prompt                 ; Message address
    mov rdx, prompt_len             ; Message length
    syscall

    ; --- Read Input ---
    sub rsp, 16                     ; Allocate 16 bytes on stack for input buffer
    mov rsi, rsp                    ; Buffer address
    mov rax, 0                      ; sys_read
    mov rdi, 0                      ; stdin
    mov rdx, 16                     ; Max bytes to read
    syscall                         ; Read input, bytes read in RAX

    ; --- Validate Input Length ---
    cmp rax, 2                      ; Check for single digit + newline (2 bytes)
    je check_single_digit
    cmp rax, 3                      ; Check for "10" + newline (3 bytes)
    je check_ten
    jmp invalid_input               ; Otherwise, invalid length

; ------------------------- Handle "10" Input -------------------------
check_ten:
    movzx eax, byte [rsp]           ; Load first char ('1'?)
    cmp eax, '1'
    jne invalid_input
    movzx eax, byte [rsp+1]         ; Load second char ('0'?)
    cmp eax, '0'
    jne invalid_input
    mov edi, 10                     ; Valid "10", set guess to 10
    jmp valid_input

; ------------------------- Handle Single Digit Input -------------------------
check_single_digit:
    movzx eax, byte [rsp]           ; Load the digit character
    cmp eax, '1'                    ; Check if >= '1'
    jl invalid_input
    cmp eax, '9'                    ; Check if <= '9'
    jg invalid_input
    sub eax, '0'                    ; Convert ASCII digit to integer
    mov edi, eax                    ; Store integer guess in EDI
    jmp valid_input

; ------------------------- Handle Invalid Input -------------------------
invalid_input:
    mov rax, 1                      ; sys_write
    mov rdi, 1                      ; stdout
    mov rsi, invalid_msg
    mov rdx, invalid_msg_len
    syscall                         ; Display invalid message
    add rsp, 16                     ; Clean up stack buffer
    jmp game_loop                   ; Loop back to prompt again

; ------------------------- Process Valid Input -------------------------
valid_input:
    add rsp, 16                     ; Clean up stack buffer (input now parsed into EDI)

    ; --- Range Check (Safety) ---
    cmp edi, 1
    jl invalid_input_after_parse    ; Should not happen if parsing is correct
    cmp edi, 10
    jg invalid_input_after_parse    ; Should not happen

    ; --- Compare Guess (EDI) with Target (EBX) ---
    cmp edi, ebx
    je correct                      ; Guessed correctly!
    jl too_low                      ; Guess is too low
                                    ; Otherwise, fall through to too_high

; ------------------------- Feedback: Too High -------------------------
too_high:
    mov rax, 1                      ; sys_write
    mov rdi, 1                      ; stdout
    mov rsi, high_msg
    mov rdx, high_msg_len
    syscall
    jmp game_loop                   ; Try again

; ------------------------- Feedback: Too Low -------------------------
too_low:
    mov rax, 1                      ; sys_write
    mov rdi, 1                      ; stdout
    mov rsi, low_msg
    mov rdx, low_msg_len
    syscall
    jmp game_loop                   ; Try again

; ------------------------- Feedback: Correct -------------------------
correct:
    mov rax, 1                      ; sys_write
    mov rdi, 1                      ; stdout
    mov rsi, correct_msg
    mov rdx, correct_msg_len
    syscall                         ; Display correct message

    ; --- Exit Program ---
    mov rax, 60                     ; sys_exit
    xor rdi, rdi                    ; Exit code 0 (success)
    syscall

; ------------------------- Post-Parse Invalid (Safety) -------------------------
invalid_input_after_parse:
    mov rax, 1                      ; sys_write
    mov rdi, 1                      ; stdout
    mov rsi, invalid_msg
    mov rdx, invalid_msg_len
    syscall
    jmp game_loop                   ; Try again (stack already cleaned)

; ========================= End of Code =========================
