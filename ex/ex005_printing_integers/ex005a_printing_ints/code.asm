;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define LOAD_ADDRESS 0x00020000 ; pretty much any number >0 works
%define CODE_SIZE END-(LOAD_ADDRESS+0x78) ; everything beyond HEADER is code
%define PRINT_BUFFER_SIZE 4096

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;HEADER;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BITS 64
org LOAD_ADDRESS
ELF_HEADER:
	db 0x7F,"ELF" ; magic number to indicate ELF file
	db 0x02 ; 0x1 for 32-bit, 0x2 for 64-bit
	db 0x01 ; 0x1 for little endian, 0x2 for big endian
	db 0x01 ; 0x1 for current version of ELF
	db 0x09 ; 0x9 for FreeBSD, 0x3 for Linux (doesn't seem to matter)
	db 0x00 ; ABI version (ignored?)
	times 7 db 0x00 ; 7 padding bytes
	dw 0x0002 ; executable file
	dw 0x003E ; AMD x86-64 
	dd 0x00000001 ; version 1
	dq START ; entry point for our program
	dq 0x0000000000000040 ; 0x40 offset from ELF_HEADER to PROGRAM_HEADER
	dq 0x0000000000000000 ; section header offset (we don't have this)
	dd 0x00000000 ; unused flags
	dw 0x0040 ; 64-byte size of ELF_HEADER
	dw 0x0038 ; 56-byte size of each program header entry
	dw 0x0001 ; number of program header entries (we have one)
	dw 0x0000 ; size of each section header entry (none)
	dw 0x0000 ; number of section header entries (none)
	dw 0x0000 ; index in section header table for section names (waste)
PROGRAM_HEADER:
	dd 0x00000001 ; 0x1 for loadable program segment
	dd 0x00000007 ; read/write/execute flags
	dq 0x0000000000000078 ; offset of code start in file image (0x40+0x38)
	dq LOAD_ADDRESS+0x78 ; virtual address of segment in memory
	dq 0x0000000000000000 ; physical address of segment in memory (ignored?)
	dq CODE_SIZE ; size (bytes) of segment in file image
	dq CODE_SIZE+PRINT_BUFFER_SIZE ; size (bytes) of segment in memory
	dq 0x0000000000000000 ; alignment (doesn't matter, only 1 segment)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INCLUDES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%include "syscalls.asm"	; requires syscall listing for your OS in lib/sys/	

%include "lib/io/print_chars.asm"
; void print_chars(int {rdi}, char* {rsi}, int {rdx});

%include "lib/io/print_int_b.asm"
; void print_int_b(int {rdi}, int {rsi});

%include "lib/io/print_int_o.asm"
; void print_int_o(int {rdi}, int {rsi});

%include "lib/io/print_int_h.asm"
; void print_int_h(int {rdi}, int {rsi});

%include "lib/io/print_int_d.asm"
; void print_int_d(int {rdi}, int {rsi});

%include "lib/sys/exit.asm"	
; void exit(byte {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:

	mov rdi,SYS_STDOUT		; STDOUT file descriptor

	mov rsi,[VALUE]
	call print_int_b		; print [VALUE] in binary
	
	mov rsi,GRAMMAR
	mov rdx,1
	call print_chars		; print newline

	mov rsi,[VALUE]
	call print_int_o		; print [VALUE] in octal
	
	mov rsi,GRAMMAR
	mov rdx,1			; print newline
	call print_chars

	mov rsi,[VALUE]
	call print_int_h		; print [VALUE] in hexadecimal
	
	mov rsi,GRAMMAR
	mov rdx,1			; print newline
	call print_chars

	mov rsi,[VALUE]
	call print_int_d		; print [VALUE] in decimal
	
	mov rsi,GRAMMAR
	mov rdx,1
	call print_chars		; print newline

	call print_buffer_flush

	xor dil,dil
	call exit	

VALUE:
	dq 1337

GRAMMAR:
	db `\n`

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
