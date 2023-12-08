;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define LOAD_ADDRESS 0x00020000 ; pretty much any number >0 works
%define CODE_SIZE END-(LOAD_ADDRESS+0x78) ; everything beyond HEADER is code
%define PRINT_BUFFER_SIZE 4096
%define HEAP_SIZE 0x2000000 ; ~32 MB

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

%include "lib/mem/memcopy.asm"
; void memcopy(long* {rdi}, long* {rsi}, ulong {rdx});

%include "lib/mem/heap_init.asm"
; void heap_init(void);

%include "lib/io/framebuffer/framebuffer_init.asm"
; void framebuffer_init(void);

%include "lib/io/framebuffer/framebuffer_mouse_init.asm"
; void framebuffer_mouse_init(void);

%include "lib/io/framebuffer/framebuffer_mouse_poll.asm"
; void framebuffer_mouse_poll(void);

%include "lib/io/bitmap/set_foreground.asm"
; void set_foreground(void* {rdi}, void* {rsi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});

%include "lib/io/framebuffer/framebuffer_clear.asm"
; void framebuffer_clear(uint {rdi});

%include "lib/io/framebuffer/framebuffer_flush.asm"
; void framebuffer_flush(void);

%include "lib/io/bitmap/set_pixel.asm"
; void set_pixel(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d});

%include "lib/io/bitmap/set_line.asm"
; void set_line(void* {rdi}, int {esi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});

%include "lib/mem/memset.asm"
; void memset(void* {rdi}, char {sil}, ulong {rdx});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; NOTE: NEED TO RUN THIS AS SUDO

START:

	call heap_init

	call framebuffer_init
	
	call framebuffer_mouse_init

	mov rdi,[framebuffer_init.framebuffer_size]
	call heap_alloc
	mov r15,rax	; buffer to combine multiple layers

	; clear the screen to start
	mov rdi,0xFF000000
	call framebuffer_clear
	call framebuffer_flush
	
	; copy this to the intermediate buffer to start
	mov rdi,r15
	mov rsi,[framebuffer_init.framebuffer_address]
	mov rdx,[framebuffer_init.framebuffer_size]
	call memcopy
	
	; these track the previous cursor location (while holding left mouse)
	xor r12,r12 ; x
	xor r13,r13 ; y

.loop:
	; check mouse status	
	call framebuffer_mouse_poll

	; if right click isn't pressed, don't clear screen
	cmp byte [framebuffer_mouse_init.mouse_state],2
	jne .no_clear
	mov rdi,r15
	xor sil,sil
	mov rdx,[framebuffer_init.framebuffer_size]
	call memset

.no_clear:
	xor rax,rax
	; if left click isn't pressed, nothing to draw but cursor
	cmp byte [framebuffer_mouse_init.mouse_state],1
	cmovne r12,rax
	cmovne r13,rax
	jne .no_drawing

	; draw an orange pixel to the intermediate buffer
	mov rdi,r15
	mov rsi,0x1FFFF8200
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	mov r8d,[framebuffer_mouse_init.mouse_x]
	mov r9d,[framebuffer_mouse_init.mouse_y]
	call set_pixel

	test r12,r12
	jz .no_line
	test r13,r13
	jz .no_line
	mov r10d,r12d
	mov r11d,r13d
	call set_line	

.no_line:
	mov r12d,r8d
	mov r13d,r9d

.no_drawing:
	
;;; combine layers to plot the cursor to the screen
	
	; first copy intermediate buffer to framebuffer
	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,r15
	mov rdx,[framebuffer_init.framebuffer_size]
	call memcopy

	; then copy the cursor as foreground onto the framebuffer
	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,PEPE_BIG
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	mov r8d,26;13;2
	mov r9d,14;7;2
	mov r10d,[framebuffer_mouse_init.mouse_x]
	mov r11d,[framebuffer_mouse_init.mouse_y]
	call set_foreground

	; flush output to the screen
	call framebuffer_flush

	jmp .loop

CURSOR:	; orange square, 2x2
	times 4 dd 0xFFFF8200

%define G 0xFF2B7544
%define W 0xFFFFFFFF
%define B 0xFF000000
%define T 0x00000000
%define S 0xFF2945E3
%define R 0xFF780016

PEPE_SMALL: ; (13x7)
	dd 0,0,0,G,G,0,G,G,0,0,0,0,0
	dd 0,0,G,G,G,G,G,G,G,0,0,0,0
	dd G,0,G,B,W,W,B,W,G,G,0,0,0
	dd 0,G,0,G,G,G,G,G,G,G,0,0,G
	dd 0,0,G,R,R,R,R,G,G,G,G,0,G
	dd 0,0,0,S,G,G,G,G,G,G,G,0,G
	dd 0,0,0,0,S,S,S,S,S,S,S,S,0

PEPE_BIG: ; (26x14)
	dd 0,0,0,0,0,0,G,G,G,G,0,0,G,G,G,G,0,0,0,0,0,0,0,0,0,0
	dd 0,0,0,0,0,0,G,G,G,G,0,0,G,G,G,G,0,0,0,0,0,0,0,0,0,0
	dd 0,0,0,0,G,G,G,G,G,G,G,G,G,G,G,G,G,G,0,0,0,0,0,0,0,0
	dd 0,0,0,0,G,G,G,G,G,G,G,G,G,G,G,G,G,G,0,0,0,0,0,0,0,0
	dd G,G,0,0,G,G,B,B,W,W,W,W,B,B,W,W,G,G,G,G,0,0,0,0,0,0
	dd G,G,0,0,G,G,B,B,W,W,W,W,B,B,W,W,G,G,G,G,0,0,0,0,0,0
	dd 0,0,G,G,0,0,G,G,G,G,G,G,G,G,G,G,G,G,G,G,0,0,0,0,G,G
	dd 0,0,G,G,0,0,G,G,G,G,G,G,G,G,G,G,G,G,G,G,0,0,0,0,G,G
	dd 0,0,0,0,G,G,R,R,R,R,R,R,R,R,G,G,G,G,G,G,G,G,0,0,G,G
	dd 0,0,0,0,G,G,R,R,R,R,R,R,R,R,G,G,G,G,G,G,G,G,0,0,G,G
	dd 0,0,0,0,0,0,S,S,G,G,G,G,G,G,G,G,G,G,G,G,G,G,0,0,G,G
	dd 0,0,0,0,0,0,S,S,G,G,G,G,G,G,G,G,G,G,G,G,G,G,0,0,G,G
	dd 0,0,0,0,0,0,0,0,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,0,0
	dd 0,0,0,0,0,0,0,0,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,0,0

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)

