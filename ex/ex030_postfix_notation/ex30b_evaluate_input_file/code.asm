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

%include "lib/io/print_float.asm"

%include "lib/io/print_chars.asm"

%include "lib/math/expressions/parse/evaluate_postfix_string.asm"

%include "lib/sys/exit.asm"

%include "lib/io/file_open.asm"

%include "lib/io/read_chars.asm"

%include "lib/io/strlen.asm"

%include "lib/mem/memset.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:
	
	cmp byte [SYS_ARGC_START_POINTER],3
	jne .invalid_inputs

	; open input file, fd in {r14}
	mov rdi,[SYS_ARGC_START_POINTER+16]
	mov rsi,SYS_READ_ONLY
	mov rdx,SYS_DEFAULT_PERMISSIONS
	call file_open
	mov r14,rax
		
	; open output file, fd in {r15}
	mov rdi,[SYS_ARGC_START_POINTER+24]
	mov rsi,SYS_CREATE_FILE+SYS_READ_WRITE+SYS_TRUNCATE
	mov rdx,SYS_DEFAULT_PERMISSIONS
	call file_open
	mov r15,rax

	mov rdi,r14

.parse_expression:
	mov rdi,.input_buffer
	xor sil,sil
	mov rdx,80
	call memset

	mov rdi,r14
	mov rsi,.input_buffer
	mov rdx,1

.read_character_loop:
		
	call read_chars
	cmp byte [rsi], byte 10
	je .evaluate_now

	inc rsi

	test rax,rax
	jz .done
	jmp .read_character_loop

.evaluate_now:

	xor al,al
	mov [rsi],al

	mov rdi,.input_buffer
	call evaluate_postfix_string
	test rax,rax
	jnz .invalid_expression

	mov rdi,r15
	mov rdx,rsi
	sub rdx,.input_buffer	
	mov rsi,.input_buffer	
	call print_chars

	mov rsi,.grammar
	mov rdx,3
	call print_chars

	mov rsi,10	
	call print_float

	mov rsi,.grammar+3
	mov rdx,1
	call print_chars
	call print_buffer_flush

	jmp .parse_expression

.done:
	xor rdi,rdi
	call exit

.invalid_expression:

	mov rdi,r15
	mov rdx,rsi
	sub rdx,.input_buffer	
	mov rsi,.input_buffer	
	call print_chars

	mov rsi,.bogus_expression
	mov rdx,14
	call print_chars	
	call print_buffer_flush

	jmp .parse_expression

.invalid_inputs:
	mov rdi,SYS_STDOUT
	mov rsi,.incorrect_usage
	mov rdx,16
	call print_chars

	mov rdi,[SYS_ARGC_START_POINTER+8]
	call strlen

	mov rsi,rdi
	mov rdi,SYS_STDOUT
	mov rdx,rax
	call print_chars

	mov rsi,.incorrect_usage+16
	mov rdx,19

.exit:
	call print_chars
	call print_buffer_flush

	mov dil,1
	call exit

.input_buffer:
	times 80 db 0

.incorrect_usage:
	db `nah, try using ' file.in file.out'\n`

.bogus_expression:
	db ` is bogus lol\n`

.grammar:
	db ` = \n`

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
