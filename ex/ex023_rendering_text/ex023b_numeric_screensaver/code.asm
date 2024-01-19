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

%include "lib/mem/heap_init.asm"
; void heap_init(void);

%include "lib/io/bitmap/set_text.asm"
; void set_text(void* {rdi}, int {esi}, int {edx}, int {ecx},
;	 int {r8d}, int {r9d}, int {r10d}, char* {r11}, void* {r12});

%include "lib/io/bitmap/SCHIZOFONT.asm"

%include "lib/io/framebuffer/framebuffer_init.asm"
; void framebuffer_init(void);

%include "lib/io/framebuffer/framebuffer_clear.asm"
; void framebuffer_clear(uint {rdi});

%include "lib/io/framebuffer/framebuffer_flush.asm"
; void framebuffer_flush(void);

%include "lib/math/rand/rand_int_array.asm"
; void rand_int_array(long* {rdi}, int {rsi}, uint {rdx}, 
;			signed long {rcx}, signed long {r8});

%include "lib/math/rand/rand_int.asm"
; signed long {rax} rand_int(signed long {rdi}, signed long {rsi});

%include "lib/io/bitmap/set_filled_rect.asm"
; void set_filled_rect(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; NOTE: NEED TO RUN THIS AS SUDO

START:

	call heap_init
	call framebuffer_init

	; init black screen
	xor rdi,rdi	
	mov rdi,0x1FF000000
	call framebuffer_clear
	
.loop:
	; flush to screen
	call framebuffer_flush

	; randomize x positions
	mov rdi,.random_positions
	xor rsi,rsi
	mov rdx,2
	xor rcx,rcx
	mov r8d,[framebuffer_init.framebuffer_width]
	call rand_int_array	

	; randomize y positions
	mov rdi,.random_positions+16
	xor rsi,rsi
	mov rdx,2
	xor rcx,rcx
	mov r8d,[framebuffer_init.framebuffer_height]
	call rand_int_array	

	; randomize dimensions
	mov rdi,.random_dimensions
	xor rsi,rsi
	mov rdx,2
	mov rcx,1
	mov r8d,[framebuffer_init.framebuffer_height]
	shr r8d,3
	call rand_int_array	

	; randomize colors
	mov rdi,.random_colors
	xor rsi,rsi
	mov rdx,2
	xor rcx,rcx
	mov r8d,0xFFFFFFFF
	call rand_int_array	

	; plot a random color random sized rectangle randomly on screen
	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,[.random_colors+0]
	or rsi,0x100000000
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	mov r8d,dword [.random_positions+0]
	mov r9d,dword [.random_positions+16]
	mov r10d,r8d
	mov r11d,r9d
	add r10d,dword [.random_dimensions+0]
	add r11d,dword [.random_dimensions+8]
	call set_filled_rect

	; pick a random capital letter
	mov rdi,65
	mov rsi,90
	call rand_int
	mov byte [.number_buffer],al

	; pick a random font size
	mov rdi,2
	mov rsi,8
	call rand_int	

	; plot a random color random sized character
	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,[.random_colors+0]
	or rsi,0x1FF000000
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	mov r8d,dword [.random_positions+8]
	mov r9d,dword [.random_positions+24]
	mov r10,rax
	mov r11,.number_buffer
	mov r12,SCHIZOFONT	
	call set_text

	jmp .loop	

.number_buffer:
	db 0,0

.random_positions:	; x0, x1, y0, y1
	times 4 dq 0

.random_dimensions:
	times 2 dq 0

.random_colors:
	times 2 dq 0


END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)

