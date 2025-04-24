; Description: A simple number guessing game for Linux x86-64.
;              The program generates a pseudo-random number between 1 and 10
;              and prompts the user to guess the number until they are correct.
;
; Build Instructions (using NASM and ld):
; nasm -f elf64 guessing_game.asm -o guessing_game.o
; ld guessing_game.o -o guessing_game

; ==============================================================================
; Data Section
; ==============================================================================
; Contains initialized data (constants, strings).
section .data
    ; --- User Interface Strings ---
    prompt          db "Guess a number (1-10): ", 0  ; Prompt message (null-terminated for convenience, though not strictly needed for write)
    prompt_len      equ $ - prompt                  ; Calculate length of the prompt string automatically

    low_msg         db "Too low!", 10               ; Message for guess too low (includes newline)
    low_msg_len     equ $ - low_msg                 ; Calculate length of the 'too low' message

    high_msg        db "Too high!", 10              ; Message for guess too high (includes newline)
    high_msg_len    equ $ - high_msg                ; Calculate length of the 'too high' message

    correct_msg     db "Correct!", 10               ; Message for correct guess (includes newline)
    correct_msg_len equ $ - correct_msg             ; Calculate length of the 'correct' message

    invalid_msg     db "Invalid input! ", 10        ; Message for invalid input (includes newline)
    invalid_msg_len equ $ - invalid_msg             ; Calculate length of the 'invalid input' message

; ==============================================================================
; Text Section
; ==============================================================================
; Contains the program code (instructions).
section .text
    global _start                   ; Make the _start label globally visible (entry point for the linker)

; ------------------------------------------------------------------------------
; Program Entry Point
; ------------------------------------------------------------------------------
_start:
    ; --- Seed and Generate Target Number (Pseudo-Random) ---
    ; Uses the CPU's Time Stamp Counter (TSC) as a basic seed. Note: This is
    ; not cryptographically secure randomness.
    rdtsc                           ; Read Time Stamp Counter into EDX:EAX (high:low 64 bits)
    mov ecx, 10                     ; Set the divisor to 10 for modulo operation
    xor edx, edx                    ; Clear EDX (high part of dividend) for 32-bit division
                                    ; We only use the lower 32 bits (EAX) from TSC for simplicity.
    div ecx                         ; Divide EDX:EAX by ECX (10). Quotient in EAX, Remainder in EDX.
                                    ; The remainder (EDX) will be 0-9.
    add edx, 1                      ; Add 1 to the remainder to get a range of 1-10.
    mov ebx, edx                    ; Store the target number (1-10) in EBX for later comparison.
                                    ; Using EBX as it's a callee-saved register (though not critical here).

; ------------------------------------------------------------------------------
; Main Game Loop
; ------------------------------------------------------------------------------
game_loop:
    ; --- Prompt User for Input ---
    ; Use the sys_write system call to display the prompt message.
    mov rax, 1                      ; System call number for sys_write
    mov rdi, 1                      ; File descriptor 1: stdout (standard output)
    mov rsi, prompt                 ; Address of the string to write (prompt message)
    mov rdx, prompt_len             ; Number of bytes to write (length of prompt)
    syscall                         ; Invoke the kernel to perform the write operation

    ; --- Read User Input ---
    ; Use the sys_read system call to read from standard input.
    sub rsp, 16                     ; Allocate 16 bytes on the stack for the input buffer.
                                    ; This provides space for input like "10\n" plus padding.
    mov rsi, rsp                    ; Point RSI to the beginning of the allocated buffer.
    mov rax, 0                      ; System call number for sys_read
    mov rdi, 0                      ; File descriptor 0: stdin (standard input)
    mov rdx, 16                     ; Maximum number of bytes to read into the buffer (RSI)
    syscall                         ; Invoke the kernel to perform the read operation.
                                    ; RAX will contain the number of bytes actually read.

    ; --- Input Validation (Length Check) ---
    ; Check the number of bytes read (returned in RAX) to determine if the input
    ; could potentially be a valid single digit (e.g., "5\n" -> 2 bytes) or
    ; the number ten ("10\n" -> 3 bytes). Includes the newline character.
    cmp rax, 2                      ; Is the input exactly 2 bytes long? (e.g., '1' + newline)
    je check_single_digit           ; If yes, jump to handle single-digit input.
    cmp rax, 3                      ; Is the input exactly 3 bytes long? (e.g., '10' + newline)
    je check_ten                    ; If yes, jump to check if it's specifically "10".
    jmp invalid_input               ; If neither 2 nor 3 bytes, the input format is invalid.

; ------------------------------------------------------------------------------
; Input Handling: Check for "10"
; ------------------------------------------------------------------------------
check_ten:
    ; Input length was 3 bytes. Verify it's exactly "10\n".
    movzx eax, byte [rsp]           ; Load the first byte from the buffer into EAX (zero-extended).
                                    ; Using movzx ensures upper bits of EAX are zero.
    cmp eax, '1'                    ; Is the first character '1'?
    jne invalid_input               ; If not '1', jump to invalid input handling.

    movzx eax, byte [rsp+1]         ; Load the second byte from the buffer into EAX (zero-extended).
    cmp eax, '0'                    ; Is the second character '0'?
    jne invalid_input               ; If not '0', jump to invalid input handling.

    ; If we reach here, the input is "10\n".
    mov edi, 10                     ; Set EDI to the integer value 10. EDI will hold the user's guess.
    jmp valid_input                 ; Jump to the common validation/comparison logic.

; ------------------------------------------------------------------------------
; Input Handling: Check for Single Digit ('1'-'9')
; ------------------------------------------------------------------------------
check_single_digit:
    ; Input length was 2 bytes. Verify it's a digit '1'-'9' followed by newline.
    movzx eax, byte [rsp]           ; Load the first byte (the digit) into EAX (zero-extended).
    cmp eax, '1'                    ; Compare ASCII value with '1'.
    jl invalid_input                ; If less than '1', it's invalid (handles '0' case too).
    cmp eax, '9'                    ; Compare ASCII value with '9'.
    jg invalid_input                ; If greater than '9', it's invalid.

    ; If we reach here, the character is a valid digit '1' through '9'.
    sub eax, '0'                    ; Convert the ASCII digit character to its integer equivalent
                                    ; (e.g., '5' (0x35) - '0' (0x30) = 5 (0x05)).
    mov edi, eax                    ; Move the resulting integer value into EDI.
    jmp valid_input                 ; Jump to the common validation/comparison logic.

; ------------------------------------------------------------------------------
; Input Handling: Invalid Input
; ------------------------------------------------------------------------------
invalid_input:
    ; Display the "Invalid input!" message.
    mov rax, 1                      ; sys_write system call
    mov rdi, 1                      ; stdout
    mov rsi, invalid_msg            ; Address of the invalid message string
    mov rdx, invalid_msg_len        ; Length of the message
    syscall                         ; Invoke kernel

    ; Clean up stack from this attempt before looping back.
    add rsp, 16                     ; Deallocate the 16-byte buffer from the stack.

    jmp game_loop                   ; Jump back to the start of the game loop to prompt again.

; ------------------------------------------------------------------------------
; Input Handling: Valid Input Processing
; ------------------------------------------------------------------------------
valid_input:
    ; Clean up the stack now that input is parsed.
    add rsp, 16                     ; Deallocate the 16-byte buffer from the stack.

    ; --- Validate Number Range (Redundant Check) ---
    ; Although check_single_digit and check_ten implicitly handle the 1-10 range,
    ; this provides an explicit safeguard. EDI holds the parsed integer guess.
    cmp edi, 1                      ; Compare user's guess (EDI) with 1.
    jl invalid_input_after_parse    ; If less than 1 (shouldn't happen with current logic, but safe).
    cmp edi, 10                     ; Compare user's guess (EDI) with 10.
    jg invalid_input_after_parse    ; If greater than 10 (shouldn't happen).

    ; --- Compare Guess with Target Number ---
    ; EBX holds the target random number generated at the start.
    ; EDI holds the user's valid integer guess (1-10).
    cmp edi, ebx                    ; Compare the guess (EDI) with the target (EBX).
    je correct                      ; If equal, jump to the 'correct' handler.
    jl too_low                      ; If guess < target (Jump Less), jump to 'too_low'.
    ; If neither equal nor less, it must be greater. Fall through to 'too_high'.

; ------------------------------------------------------------------------------
; Guess Feedback: Too High
; ------------------------------------------------------------------------------
too_high:
    ; Display the "Too high!" message.
    mov rax, 1                      ; sys_write system call
    mov rdi, 1                      ; stdout
    mov rsi, high_msg               ; Address of the 'too high' message string
    mov rdx, high_msg_len           ; Length of the message
    syscall                         ; Invoke kernel
    jmp game_loop                   ; Go back for another guess.

; ------------------------------------------------------------------------------
; Guess Feedback: Too Low
; ------------------------------------------------------------------------------
too_low:
    ; Display the "Too low!" message.
    mov rax, 1                      ; sys_write system call
    mov rdi, 1                      ; stdout
    mov rsi, low_msg                ; Address of the 'too low' message string
    mov rdx, low_msg_len            ; Length of the message
    syscall                         ; Invoke kernel
    jmp game_loop                   ; Go back for another guess.

; ------------------------------------------------------------------------------
; Guess Feedback: Correct
; ------------------------------------------------------------------------------
correct:
    ; Display the "Correct!" message.
    mov rax, 1                      ; sys_write system call
    mov rdi, 1                      ; stdout
    mov rsi, correct_msg            ; Address of the 'correct' message string
    mov rdx, correct_msg_len        ; Length of the message
    syscall                         ; Invoke kernel

    ; --- Exit Program ---
    ; Use the sys_exit system call to terminate the program cleanly.
    mov rax, 60                     ; System call number for sys_exit
    xor rdi, rdi                    ; Exit code 0 (success). XORing a register with itself zeros it.
    syscall                         ; Invoke the kernel to terminate the process.

; ------------------------------------------------------------------------------
; Helper Label for Post-Parse Invalid Input (Safety Net)
; ------------------------------------------------------------------------------
; This label is jumped to if the range check within valid_input fails.
; It ensures the invalid message is shown even in this unlikely scenario.
invalid_input_after_parse:
    ; Display the "Invalid input!" message.
    mov rax, 1                      ; sys_write system call
    mov rdi, 1                      ; stdout
    mov rsi, invalid_msg            ; Address of the invalid message string
    mov rdx, invalid_msg_len        ; Length of the message
    syscall                         ; Invoke kernel
    jmp game_loop                   ; Go back for another guess (stack already cleaned in valid_input).

; ==============================================================================
; End of Code
; ==============================================================================

