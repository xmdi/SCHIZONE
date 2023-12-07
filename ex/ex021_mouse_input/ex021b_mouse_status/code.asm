;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define LOAD_ADDRESS 0x00020000 ; pretty much any number >0 works
%define CODE_SIZE END-(LOAD_ADDRESS+0x78) ; everything beyond HEADER is code
%define PRINT_BUFFER_SIZE 4096
%define HEAP_SIZE 0x1000000 ; ~16 MB

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
	dq CODE_SIZE+PRINT_BUFFER_SIZE+HEAP_SIZE ; size (bytes) of segment in memory
	dq 0x0000000000000000 ; alignment (doesn't matter, only 1 segment)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INCLUDES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%include "syscalls.asm"	; requires syscall listing for your OS in lib/sys/	

%include "lib/io/file_open.asm"
; int {rax} file_open(char* {rdi}, int {rsi}, int {rdx});

%include "lib/mem/heap_init.asm"
; void heap_init(void);

%include "lib/io/framebuffer/framebuffer_init.asm"
; void framebuffer_init(void);

%include "lib/io/framebuffer/framebuffer_mouse_init.asm"
; void framebuffer_mouse_init(void);

%include "lib/io/framebuffer/framebuffer_mouse_poll.asm"
; void framebuffer_mouse_poll(void);

%include "lib/io/bitmap/set_pixel.asm"
; void set_pixel(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d});

%include "lib/io/framebuffer/framebuffer_clear.asm"
; void framebuffer_clear(uint {rdi});

%include "lib/io/framebuffer/framebuffer_flush.asm"
; void framebuffer_flush(void);
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; NOTE: NEED TO RUN THIS AS SUDO

START:

	call heap_init

	call framebuffer_init
	
	call framebuffer_mouse_init

	; clear the screen to start
	xor rdi,rdi
	call framebuffer_clear
	call framebuffer_flush
	
	mov r13,0x1FFFF8200	; left click color
	mov r14,0x1FFFF0000	; right click color
	mov r15,0x1FF00FFFF	; middle click color

	; framebuffer width and height	
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	
.loop:
	; check mouse status	
	call framebuffer_mouse_poll

	; if no button is pressed, go back up
	cmp byte [framebuffer_mouse_init.mouse_state],0
	je .loop

	; change "cursor" color based on which mouse button is pressed
	cmp byte [framebuffer_mouse_init.mouse_state],0b001
	cmove rsi,r13
	cmp byte [framebuffer_mouse_init.mouse_state],0b010
	cmove rsi,r14
	cmp byte [framebuffer_mouse_init.mouse_state],0b100
	cmove rsi,r15

	; draw a 2x2 mouse "cursor" directly to the framebufferbuffer
	mov rdi,[framebuffer_init.framebuffer_address]
	mov r8d,[framebuffer_mouse_init.mouse_x]
	mov r9d,[framebuffer_mouse_init.mouse_y]
	call set_pixel
	inc r8d
	call set_pixel
	inc r9d
	call set_pixel
	dec r8d
	call set_pixel

	; flush output to the screen
	call framebuffer_flush

	jmp .loop

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)

