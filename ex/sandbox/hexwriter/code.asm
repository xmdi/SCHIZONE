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

%include "lib/io/read_chars.asm"
; int {rax} read_chars(int {rdi}, char* {rsi}, int {rdx});

%include "lib/sys/exit.asm"	
; void exit(byte {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:

	push SYS_ARGC_START_POINTER

	; open input file
	mov rdi,[SYS_ARGC_START_POINTER+16] ; command line arg
	mov esi,SYS_READ_ONLY	; put READ_ONLY flags in {rsi}
	mov edx,SYS_DEFAULT_PERMISSIONS	; default R/W flags in {rdx}
	mov al,SYS_OPEN
	syscall			; syscall to open file
	mov r14,rax	

	; open output file
	pop rdi
	mov rdi,[rdi+24] ; command line arg
	mov esi,SYS_CREATE_FILE
	mov edx,SYS_DEFAULT_PERMISSIONS	; default R/W flags in {rdx}
	mov al,SYS_OPEN
	syscall			; syscall to open file
	mov r15,rax	

.loop:	; loop through input file

	; read from input file to buffer
	mov rdi,r14
	mov rsi,.READ_BUFFER
	mov rdx,128
	call read_chars

	mov rdi,SYS_STDOUT
	mov rsi,.READ_BUFFER
	mov rdx,8
	mov rax,SYS_WRITE
	syscall

	jmp .here

	mov dil,al
	call exit

	mov rcx,rax
	mov rbp,.READ_BUFFER

	xor r8,r8

.byte_loop:	; loop through buffer converting bytes from ASCII to binary

	cmp byte [rbp],32	; space
	je .skip_char
	cmp byte [rbp],44	; comma
	je .skip_char
	cmp byte [rbp],59	; semicolon
	je .skip_char;.toggle_comment_on
	cmp byte [rbp],48
	jl .invalid_character	
	cmp byte [rbp],58
	jl .numeric	
	cmp byte [rbp],70
	jg .invalid_character	
	cmp byte [rbp],64
	jg .alphabetic


.invalid_character:

	mov bl,byte [rbp]
	mov byte [.error_text+10],bl
.here:
	mov rdi,SYS_STDOUT
	mov rsi,.error_text
	mov rdx,12
	mov rax,SYS_WRITE
	syscall
	
	mov dil,-1
	call exit

.numeric:
	mov bl,byte [rbp]
	sub bl,48

.alphabetic:
	mov bl,byte [rbp]
	sub bl,65

.write_char:
	
	test r8,1
	jz .not_this_one
	
	add bl,r9b
	mov [.WRITE_BUFFER],bl

	mov rdi,r15
	mov rsi,.WRITE_BUFFER
	mov rdx,1
	mov rax,SYS_WRITE
	syscall

	jmp .skip_char

.not_this_one:
	mov r9b,bl
	shl r9b,4

.skip_char:

	inc r8

	inc rbp
	dec rcx
	jnz .byte_loop

	xor dil,dil
	call exit
	

.READ_BUFFER:
	times 128 db 0
.WRITE_BUFFER:
	times 1 db 0 
.error_text:
	db `ERROR on:  \n`

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
