section .data
    menu db "Select a level (1-10): ", 0xA
    menuLen equ $ - menu

    prompt db "Enter your guess: ", 0
    promptLen equ $ - prompt

    correctMsg db "Correct!", 0xA
    correctMsgLen equ $ - correctMsg

    tryMsg db "Incorrect! Try again!", 0xA
    tryMsgLen equ $ - tryMsg

section .bss
  option resb 4          
  guess resb 32          
  secretWordBuf resb 16 

section .text
    global _start

_start:
    ; --- Show difficulty menu ---
    mov rax, 1             ; sys_write
    mov rdi, 1             ; stdout
    mov rsi, menu
    mov rdx, menuLen
    syscall

    ; --- Read difficulty option ---
    mov rax, 0             ; sys_read
    mov rdi, 0             ; stdin
    mov rsi, option
    mov rdx, 4
    syscall



    mov rax, 60       ; syscall number 60 for sys_exit
    mov rdi, 0      ; exit code 0
    syscall