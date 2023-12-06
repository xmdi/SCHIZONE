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
; int {rax} file_open(char* {rdi}, int {rsi}, int {rdx});

%include "lib/io/print_chars.asm"
; void print_chars(int {rdi}, char* {rsi}, uint {rdx});

%include "lib/io/print_int_d.asm"
; void print_int_d(int {rdi}, int {rsi});


%include "lib/io/framebuffer/framebuffer_mouse_init.asm"
%include "lib/io/framebuffer/framebuffer_mouse_poll.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; NOTE: NEED TO RUN THIS AS SUDO

START:

	mov rdi,.filename
	mov rsi,SYS_READ_WRITE
	mov rdx,SYS_DEFAULT_PERMISSIONS
	call file_open
	mov r15,rax	; save file descriptor in {r15}

.loop:
	mov rax,SYS_READ
	mov rdi,r15
	mov rsi,.buffer
	mov rdx,4
	syscall

	test rax,rax
	js .loop

	; first byte
	mov rdi,SYS_STDOUT

	xor rsi,rsi
	mov esi,[.buffer]

	and esi,0x7

	test esi,0x1
	jnz .left_clicked
	test esi,0x2
	jnz .right_clicked
	test esi,0x4
	jnz .middle_clicked
	jmp .next
.left_clicked:
	mov rsi,.left_click
	mov rdx,11
	call print_chars
	jmp .next
.right_clicked:
	mov rsi,.right_click
	mov rdx,12
	call print_chars
	jmp .next
.middle_clicked:
	mov rsi,.middle_click
	mov rdx,13
	call print_chars
.next:
	; dx
	mov rsi,.dx
	mov rdx,5
	call print_chars

	xor rsi,rsi
	mov esi,[.buffer]

	shr esi,8
	and esi,0xff

	cmp rsi,127
	jle .no_adjust_x
	sub rsi,256
.no_adjust_x:
	call print_int_d

	; dy
	mov rsi,.dy
	mov rdx,5
	call print_chars

	xor rsi,rsi
	mov esi,[.buffer]

	shr esi,16
	and esi,0xff

	cmp rsi,127
	jle .no_adjust_y
	sub rsi,256
.no_adjust_y:
	call print_int_d

	mov rsi,.newline
	mov rdx,1
	call print_chars

	call print_buffer_flush
	
	jmp .loop

.buffer:
	times 4 db 0

.filename:
	db `/dev/input/mice\0` 
.newline:
	db `\n`
.dx:
	db ` dx: `
.dy:
	db ` dy: `
.left_click:
	db `left click\n`
.middle_click:
	db `middle click\n`
.right_click:
	db `right click\n`

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
