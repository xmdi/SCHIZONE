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

%include "lib/io/file_open.asm"	

%include "lib/io/print_chars.asm"	

%include "lib/io/read_chars.asm"	

%include "lib/io/strlen.asm"	

%include "lib/io/print_string.asm"

%include "lib/mem/strcopy.asm"

%include "lib/io/strcmp.asm"

%include "lib/sys/exit.asm"	

%include "lib/sys/getenv.asm"	

%include "lib/debug/debug.asm"	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	[map all mem.map]

START:

;	debug_stack 10,print_int_h

	mov rdi,ENV
	mov rsi,SYS_ARGC_START_POINTER
	call getenv

	mov r15,rax
	mov rdi,rax
	call strlen
	neg rax
	add rax,FILENAME
	mov rdi,rax
	mov r14,rax
	mov rsi,r15
	call strcopy
	
	mov rdi,r14
	mov rsi,SYS_CREATE_FILE+SYS_READ_WRITE+SYS_TRUNCATE
	mov rdx,SYS_DEFAULT_PERMISSIONS
	call file_open
	mov r15,rax

	movzx rcx,byte [SYS_ARGC_START_POINTER]

	cmp cl,4
	jg INVALID_INPUTS

	cmp cl,2	; handle the TUI stuff @ a later date
	jl INVALID_INPUTS

	mov rdi,[SYS_ARGC_START_POINTER+16]
	mov rsi,COMMAND_TABLE

.get_command_loop:

	call strcmp
	test rax,1
	jz .next_command

	jmp [rsi+8]

.next_command:

	add rsi,16
	cmp rsi,COMMAND_TABLE_END
	jl .get_command_loop

	jmp INVALID_INPUTS

ADD_COMMAND:
	cmp cl,3
	jne INVALID_INPUTS

	mov rdi,r15
	mov rsi,[SYS_ARGC_START_POINTER+24]
	call print_string
	call print_buffer_flush

	jmp LEAVE


DONE_COMMAND:
COMMENT_COMMAND:
LIST_COMMAND:


FIND_TASK:	; loop thru lines, searching for a task, pointed to by r14
	mov rdi,r15
	mov rsi,.buffer
	mov rdx,1

.loop:
	call read_chars
	cmp byte [rsi],`\n`
	je .line_complete
	inc rsi
	jmp .loop

.line_complete:
	mov rdi,r14
	inc rsi
	mov byte [rsi],0
	mov rsi,.buffer
	call strcmp
	cmp rax,0
	je ;TODO

.buffer:
	times 128 db 0


LEAVE:
	; exit
	xor dil,dil
	call exit	

COMMAND_TABLE:
	db `add`,0,0,0,0,0
	dq ADD_COMMAND
	db `done`,0,0,0,0
	dq DONE_COMMAND	
	db `comment`,0
	dq COMMENT_COMMAND
	db `list`,0,0,0,0
	dq LIST_COMMAND
COMMAND_TABLE_END:

INVALID_INPUTS:
	mov rdi,SYS_STDOUT
	mov rsi,.incorrect_usage
	mov rdx,.incorrect_usage_end-.incorrect_usage
	call print_chars
	call print_buffer_flush
	mov dil,1
	call exit

.incorrect_usage:
	db `\tYou did it wrong tho.\n`
.incorrect_usage_end:

ENV:
	db `HOME`,0

FILENAME_BUFFER: 
	times 128 db 0
		
FILENAME:
	db `/.todo`

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
