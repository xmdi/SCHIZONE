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

%include "lib/io/bitmap/set_pixel.asm"

%include "lib/io/framebuffer/framebuffer_init.asm"
; void framebuffer_init(void);

%include "lib/io/framebuffer/framebuffer_clear.asm"
; void framebuffer_clear(uint {rdi});

%include "lib/io/framebuffer/framebuffer_flush.asm"
; void framebuffer_flush(void);

%include "lib/sys/exit.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; NOTE: NEED TO RUN THIS AS SUDO

SCHIZOFONT:
.space:
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
.exclamation_mark:
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00000000
	db 0b00010000
	db 0b00000000
.quotation_mark:
	db 0b00101000
	db 0b00101000
	db 0b00101000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
.octothorpe:
	db 0b00100100
	db 0b00100100
	db 0b01111110
	db 0b00100100
	db 0b01111110
	db 0b00100100
	db 0b00100100
	db 0b00000000
.test:
	db 0b11111111
	db 0b11111111
	db 0b11111111
	db 0b11111111
	db 0b11111111
	db 0b11111111
	db 0b11111111
	db 0b11111111
.2:
	db 0b00111000
	db 0b01000100
	db 0b00000100
	db 0b00111000
	db 0b01000000
	db 0b01000000
	db 0b01111100
	db 0b00000000
.5:
	db 0b01111100
	db 0b01000000
	db 0b01111000
	db 0b00000100
	db 0b00000100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.6:
	db 0b00011000
	db 0b00100000
	db 0b01000000
	db 0b01111000
	db 0b01000100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.A:
	db 0b00010000
	db 0b00101000
	db 0b01000100
	db 0b01000100
	db 0b01111100
	db 0b01000100
	db 0b01000100
	db 0b00000000
.B:
	db 0b01111000
	db 0b01000100
	db 0b01000100
	db 0b01111000
	db 0b01000100
	db 0b01000100
	db 0b01111000
	db 0b00000000
.C:
	db 0b00111000
	db 0b01000100
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b01000100
	db 0b00111000
	db 0b00000000
.D:
	db 0b01111000
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01111000
	db 0b00000000
.E:
	db 0b01111100
	db 0b01000000
	db 0b01000000
	db 0b01110000
	db 0b01000000
	db 0b01000000
	db 0b01111100
	db 0b00000000
.F:
	db 0b01111100
	db 0b01000000
	db 0b01000000
	db 0b01110000
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b00000000
.G:
	db 0b00111100
	db 0b01000000
	db 0b01000000
	db 0b01001100
	db 0b01000100
	db 0b01000100
	db 0b00111100
	db 0b00000000
.H:
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01111100
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b00000000
.I:
	db 0b00111000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00111000
	db 0b00000000
.J:
	db 0b00000100
	db 0b00000100
	db 0b00000100
	db 0b00000100
	db 0b00000100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.K:
	db 0b01000100
	db 0b01001000
	db 0b01010000
	db 0b01100000
	db 0b01010000
	db 0b01001000
	db 0b01000100
	db 0b00000000
.L:
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b01111100
	db 0b00000000
.M:
	db 0b01000100
	db 0b01101100
	db 0b01010100
	db 0b01010100
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b00000000
.N:
	db 0b01000100
	db 0b01100100
	db 0b01010100
	db 0b01001100
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b00000000
.O:
	db 0b00111000
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.P:
	db 0b01111000
	db 0b01000100
	db 0b01000100
	db 0b01111000
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b00000000
.Q:
	db 0b00111000
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01010100
	db 0b01001000
	db 0b00110100
	db 0b00000000
.R:
	db 0b01111000
	db 0b01000100
	db 0b01000100
	db 0b01111000
	db 0b01010000
	db 0b01001000
	db 0b01000100
	db 0b00000000
.S:
	db 0b00111000
	db 0b01000100
	db 0b01000000
	db 0b00111000
	db 0b00000100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.T:
	db 0b01111100
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00000000
.U:
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.V:
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b00101000
	db 0b00101000
	db 0b00010000
	db 0b00010000
	db 0b00000000
.W:
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b01010100
	db 0b01010100
	db 0b01101100
	db 0b01000100
	db 0b00000000
.X:
	db 0b01000100
	db 0b01000100
	db 0b00101000
	db 0b00010000
	db 0b00101000
	db 0b01000100
	db 0b01000100
	db 0b00000000
.Y:
	db 0b01000100
	db 0b01000100
	db 0b00101000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00000000
.Z:
	db 0b01111100
	db 0b00000100
	db 0b00001000
	db 0b00010000
	db 0b00100000
	db 0b01000000
	db 0b01111100
	db 0b00000000

font_expandomatic:
	; takes character address (64 bit character) from rax and expands each bit to a pixel, rendering it to the screen
	; loop thru bytes (each row of character to output)
		; loop thru the bits (low to high)
	push r8
	push r9
	sub r9,8
	mov r12,8
.row_loop:
	mov bl, byte [rax]
	mov r14,8
.col_loop:
	mov r13b,bl
	test r13b, byte 1
	jz .no_pixel
	
	push r8
	add r8d,r14d
	call set_pixel
	
	; first pixel of row is at r8-8
	; next pixel is att r8-7

	pop r8	

.no_pixel:

	shr bl,1
	dec r14
	jnz .col_loop

	inc rax
	inc r9

	dec r12
	jnz .row_loop

	pop r9
	pop r8
	ret

START:

	call heap_init
	call framebuffer_init

	xor rdi,rdi	
	call framebuffer_clear

	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,0x1FFFFFFFF
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	
	mov r8d,500
	mov r9d,500
	mov rax,SCHIZOFONT.M ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.E ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.R ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.I ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.W ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.E ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.T ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.H ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.E ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.R ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.space ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.R ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.E ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.M ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.A ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.R ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.K ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.exclamation_mark ; put address of foreground here
	call font_expandomatic
	

	mov r8d,500
	mov r9d,516
	mov rax,SCHIZOFONT.C ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.O ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.M ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.M ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.O ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.D ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.O ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.R ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.E ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.2 ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.5 ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.6 ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.exclamation_mark ; put address of foreground here
	call font_expandomatic
	
	mov r8d,500
	mov r9d,532
	mov rax,SCHIZOFONT.L ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.O ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.B ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.S ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.T ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.E ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.R ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.C ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.H ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.U ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.N ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.G ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.exclamation_mark ; put address of foreground here
	call font_expandomatic
	
	mov r8d,500
	mov r9d,548
	mov rax,SCHIZOFONT.E ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.N ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.S ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.T ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.U ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.C ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.K ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.Y ; put address of foreground here
	call font_expandomatic
	add r8d,8
	mov rax,SCHIZOFONT.exclamation_mark ; put address of foreground here
	call font_expandomatic

	call framebuffer_flush	; flush frame to framebuffer
	
	xor dil,dil
	call exit
	

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)

