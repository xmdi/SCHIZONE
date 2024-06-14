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
	dq CODE_SIZE+PRINT_BUFFER_SIZE+512+280+144 ; size (bytes) of segment in memory
	dq 0x0000000000000000 ; alignment (doesn't matter, only 1 segment)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INCLUDES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%include "syscalls.asm"	; requires syscall listing for your OS in lib/sys/	

%include "lib/io/file_open.asm"	

%include "lib/io/print_string.asm"	

%include "lib/io/print_int_d.asm"	

%include "lib/io/strlen.asm"	

%include "lib/mem/strcopy_null.asm"

%include "lib/sys/exit.asm"	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:

	mov ax,"./"
	mov [BUFFER],ax

	; no command line input? assume current directory
	cmp byte [SYS_ARGC_START_POINTER],1
	jg .multiple_inputs
	mov rdi,.dot
	jmp .skip_in

.multiple_inputs:
	; check for exactly 2 command line inputs
	cmp byte [SYS_ARGC_START_POINTER],2
	jne .invalid_inputs

	; copy dir into buffer
	mov rdi,BUFFER
	mov rsi,[SYS_ARGC_START_POINTER+16]
	call strcopy_null

	; put slash in buffer
	call strlen
	inc rax
	mov [.buffer_offset],ax
	dec rax
	add rax,BUFFER
	mov byte [rax], byte 47

	mov rdi,[SYS_ARGC_START_POINTER+16]
.skip_in:
	mov rsi,SYS_READ_ONLY
	mov rdx,SYS_DEFAULT_PERMISSIONS
	call file_open
	mov r15,rax

.outer_loop:

	mov rax,SYS_GETDENTS
	mov rdi,r15
	mov rsi,DIRENT_STRUCT
	mov rdx,280
	syscall

	cmp rax,0
	jle .leave

	mov rbp,rax
	mov rbx,DIRENT_STRUCT

.loop:

	mov rsi,rbx
	add rsi,19
	mov r12,rsi
	
	; copy file into buffer
	mov rdi,BUFFER
	add di, word [.buffer_offset]
	call strcopy_null

	; get stat struct
	mov rax,SYS_STAT
	mov rdi,BUFFER
	mov rsi,STAT_STRUCT
	syscall

	mov rdi,SYS_STDOUT
	mov al, byte [STAT_STRUCT+25]
	test al,byte 0b01000000
	jnz .dir
;	test al,byte 0b10000000
;	jz .continue_printing
	mov al, byte [STAT_STRUCT+24]
	test al,byte 0b01000000
	jz .continue_printing

.exec:
	mov rsi,.red
	mov rdx,5
	call print_chars
	jmp .continue_printing

.dir:
	mov rsi,.yellow
	mov rdx,5
	call print_chars

.continue_printing:

	; print filename
	mov rsi,r12
	call print_string

	; reset color
	mov rsi,.reset
	mov rdx,4
	call print_chars

	mov rsi,.grammar+2
	mov rdx,3
	call print_chars

	; byte count
	mov rsi,[STAT_STRUCT+48]
	call print_int_d

	mov rsi,.grammar
	mov rdx,2
	call print_chars

	call print_buffer_flush

	movzx rax, word [rbx+16]
	add rbx,rax
	sub rbp,rax
	jnz .loop

	jmp .outer_loop

.invalid_inputs:
.leave:
	; exit
	xor dil,dil
	call exit	

.grammar:
	db `B\n - `

.dot:
	db `.`,0

.buffer_offset:
	dw 2

.yellow:
	db `\e[93m`

.red:
	db `\e[31m`

.reset:
	db `\e[0m`

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

BUFFER equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)

DIRENT_STRUCT equ (BUFFER+512)

STAT_STRUCT equ (DIRENT_STRUCT+280)

