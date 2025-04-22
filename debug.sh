nasm -f elf64 -g -F dwarf wordle.asm -o wordle.o
ld wordle.o -o wordle_prog
