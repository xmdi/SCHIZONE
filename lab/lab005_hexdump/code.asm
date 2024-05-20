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

%include "syscalls.asm" ; requires syscall listing for your OS in lib/sys/	

%include "lib/io/file_open.asm"	

%include "lib/io/read_chars.asm"	

%include "lib/io/print_chars.asm"	

%include "lib/io/print_int_h_n_digits.asm"	

%include "lib/sys/exit.asm"	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:

.multiple_inputs:
	; check for exactly 2 command line inputs
	cmp byte [SYS_ARGC_START_POINTER],2
	jne .invalid_inputs

	; copy dir into buffer
	mov rdi,[SYS_ARGC_START_POINTER+16]
	mov rsi,SYS_READ
	mov rdx,SYS_DEFAULT_PERMISSIONS
	call file_open
	mov r15,rax
	
	; check if file is actually opened	
	cmp rax,0
	jle .invalid_inputs

	xor r14,r14	; track the address

	; outer loop
.loop:
	; read 16 bytes from input file
	mov rdi,r15
	mov rsi,.buffer
	mov rdx,16
	call read_chars
	mov r12,rax
	; if 0 bytes read, or error leave
	cmp rax,0
	jle .done

	; print address
	mov rdi,SYS_STDOUT
	mov rsi,r14
	mov rdx,8
	call print_int_h_n_digits
	
	; print ": "
	mov rsi,.grammar
	mov rdx,2
	call print_chars

	mov rcx,r12	
	mov r13,.buffer
.byte_loop1:	; loop thru 16 bytes in buffer
	; print out hex byte
	mov rdi,SYS_STDOUT
	movzx rsi, byte [r13]
	mov rdx,2
	call print_int_h_n_digits
	
	; print out space
	mov rsi,.grammar+1
	mov rdx,1
	call print_chars

	inc r13
	dec rcx
	jnz .byte_loop1
	; end byte_loop1

	cmp r12,16
	je .skip

	mov rcx,16
	sub rcx,r12
.extra_spaces_loop:
	mov rsi,.grammar+1
	mov rdx,3
	call print_chars

	dec rcx
	jnz .extra_spaces_loop

.skip:
	; print out space
	mov rsi,.grammar+1
	mov rdx,1
	call print_chars

	mov rcx,r12	
	mov r13,.buffer
.byte_loop2:	; loop thru 16 bytes in buffer
	movzx rsi, byte [r13]
	; if 32<=val<=126
		; print out ascii
	; else
		; print out bogus character

	cmp rsi,32
	jl .bogus
	cmp rsi,126
	jg .bogus	
	
	mov rsi,r13
	mov rdx,1
	call print_chars

.next:

	inc r13
	dec rcx
	jnz .byte_loop2
	; end byte_loop2

	; print newline
	mov rsi,.grammar+4
	mov rdx,1
	call print_chars

	add r14,16
	jmp .loop
	; end outer loop

.done:
	; flush print buffer
	mov rdi,SYS_STDOUT
	call print_buffer_flush

.invalid_inputs:
	; exit
	xor dil,dil
	call exit	

.bogus:

	mov rsi,.bogus_byte
	mov rdx,END-.bogus_byte ;10
	call print_chars

	jmp .next

.buffer:
	times 16 db 0

.grammar: 
	db `:   \n`

.bogus_byte:
	db `\e[31m.\e[0m`

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
