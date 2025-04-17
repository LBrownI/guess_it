nasm -f elf64 wordle.asm -o wordle.o
ld wordle.o -o wordle_prog
