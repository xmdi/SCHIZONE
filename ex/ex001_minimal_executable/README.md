## Creating a Minimal Executable

In these examples we will explore a minimal executable created in various ways.

In [ex001a](ex001a_c_equivalent), we write a C program that loops infinitely. This is compiled (and linked) using a C compiler.

In [ex001b](ex001b_first_asm_program), we write the same functionality into a minimal assembly source file. This is assembled using NASM and linked using a linker (ld).

In [ex001c](ex001c_minimal_elf), we eschew the linker and generate the minimal ELF executable binary directly in NASM.
