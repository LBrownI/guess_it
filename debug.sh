nasm -f elf64 -g -F dwarf guess.asm -o guess.o
ld guess.o -o guess_prog
