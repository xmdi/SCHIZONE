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
	db 0b00000000
	db 0b00100100
	db 0b01111110
	db 0b00100100
	db 0b00100100
	db 0b01111110
	db 0b00100100
	db 0b00000000
.money:
	db 0b00010000
	db 0b00111000
	db 0b01010100
	db 0b00110000
	db 0b00011000
	db 0b01010100
	db 0b00111000
	db 0b00010000
.percent:
	db 0b01100000
	db 0b01100010
	db 0b00000100
	db 0b00001000
	db 0b00010000
	db 0b00100000
	db 0b01000110
	db 0b00000110
.ampersand:
	db 0b00110000
	db 0b01001000
	db 0b01001000
	db 0b00110000
	db 0b01010100
	db 0b01001000
	db 0b00110100
	db 0b00000000
.apostrophe:
	db 0b00100000
	db 0b00100000
	db 0b00100000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
.left_parenthesis:
	db 0b00010000
	db 0b00100000
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b00100000
	db 0b00010000
	db 0b00000000
.right_parenthesis:
	db 0b01000000
	db 0b00100000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00100000
	db 0b01000000
	db 0b00000000
.asterisk:
	db 0b00010000
	db 0b01010100
	db 0b00111000
	db 0b01111100
	db 0b00111000
	db 0b01010100
	db 0b00010000
	db 0b00010000
.plus:
	db 0b00000000
	db 0b00010000
	db 0b00010000
	db 0b01111100
	db 0b00010000
	db 0b00010000
	db 0b00000000
	db 0b00000000
.comma:
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00110000
	db 0b00110000
	db 0b01000000
.minus:
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b01111100
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
.period:
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b01100000
	db 0b01100000
	db 0b00000000
.forward_slash:
	db 0b00000000
	db 0b00000100
	db 0b00001000
	db 0b00010000
	db 0b00100000
	db 0b01000000
	db 0b00000000
	db 0b00000000
.0:
	db 0b0011100
	db 0b01000100
	db 0b01001100
	db 0b01010100
	db 0b01100100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.1:
	db 0b00010000
	db 0b00110000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00111000
	db 0b00000000
.2:
	db 0b00111000
	db 0b01000100
	db 0b00000100
	db 0b00111000
	db 0b01000000
	db 0b01000000
	db 0b01111100
	db 0b00000000
.3:
	db 0b00111000
	db 0b01000100
	db 0b00000100
	db 0b00011000
	db 0b00000100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.4:
	db 0b00001000
	db 0b00011000
	db 0b00101000
	db 0b01001000
	db 0b01111100
	db 0b00001000
	db 0b00001000
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
.7:
	db 0b01111100
	db 0b00000100
	db 0b00001000
	db 0b00010000
	db 0b00100000
	db 0b01000000
	db 0b01000000
	db 0b00000000
.8:
	db 0b00111000
	db 0b01000100
	db 0b01000100
	db 0b00111000
	db 0b01000100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.9:
	db 0b00111000
	db 0b01000100
	db 0b01000100
	db 0b00111100
	db 0b00000100
	db 0b00001000
	db 0b00110000
	db 0b00000000
.colon:
	db 0b00000000
	db 0b00000000
	db 0b00110000
	db 0b00110000
	db 0b00000000
	db 0b00110000
	db 0b00110000
	db 0b00000000
.semicolon:
	db 0b00000000
	db 0b00000000
	db 0b00110000
	db 0b00110000
	db 0b00000000
	db 0b00110000
	db 0b00110000
	db 0b00100000
.less_than:
	db 0b00001000
	db 0b00010000
	db 0b00100000
	db 0b01000000
	db 0b00100000
	db 0b00010000
	db 0b00001000
	db 0b00000000
.equals:
	db 0b00000000
	db 0b00000000
	db 0b01111100
	db 0b00000000
	db 0b01111100
	db 0b00000000
	db 0b00000000
	db 0b00000000
.greater_than:
	db 0b01000000
	db 0b00100000
	db 0b00010000
	db 0b00001000
	db 0b00010000
	db 0b00100000
	db 0b01000000
	db 0b00000000
.question_mark:
	db 0b00111000
	db 0b01000100
	db 0b00000100
	db 0b00001000
	db 0b00010000
	db 0b00000000
	db 0b00010000
	db 0b00000000
.at:
	db 0b00111000
	db 0b01000100
	db 0b00000100
	db 0b00110100
	db 0b01010100
	db 0b01010100
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
.left_square_bracket:
	db 0b01110000
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b01110000
	db 0b00000000
.back_slash:
	db 0b00000000
	db 0b01000000
	db 0b00100000
	db 0b00010000
	db 0b00001000
	db 0b00000100
	db 0b00000000
	db 0b00000000
.right_square_bracket:
	db 0b0111000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b01110000
	db 0b00000000
.caret:
	db 0b00010000
	db 0b00101000
	db 0b01000100
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
.underscore:
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b01111100
	db 0b00000000
.tick:
	db 0b01000000
	db 0b00100000
	db 0b00010000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b00000000
.a:
	db 0b00000000
	db 0b00000000
	db 0b00111000
	db 0b00000100
	db 0b00111100
	db 0b01000100
	db 0b00111100
	db 0b00000000
.b:	
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b01111000
	db 0b01000100
	db 0b01000100
	db 0b01111000
	db 0b00000000
.c:
	db 0b00000000
	db 0b00000000
	db 0b00111000
	db 0b01000100
	db 0b01000000
	db 0b01000100
	db 0b00111000
	db 0b00000000
.d:
	db 0b00000100
	db 0b00000100
	db 0b00000100
	db 0b00111100
	db 0b01000100
	db 0b01000100
	db 0b00111100
	db 0b00000000
.e:
	db 0b00000000
	db 0b00000000
	db 0b00111000
	db 0b01000100
	db 0b01111100
	db 0b01000000
	db 0b00111000
	db 0b00000000
.f:
	db 0b00010000
	db 0b00101000
	db 0b00100000
	db 0b01110000
	db 0b00100000
	db 0b00100000
	db 0b00100000
	db 0b00000000

.g:
	db 0b00000000
	db 0b00000000
	db 0b00111000
	db 0b01000100
	db 0b00111100
	db 0b00000100
	db 0b01000100
	db 0b00111000
.h:
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b01111000
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b00000000
.i:
	db 0b00000000
	db 0b00100000
	db 0b00000000
	db 0b01100000
	db 0b00100000
	db 0b00100000
	db 0b0111000
	db 0b00000000
.j:
	db 0b00000000
	db 0b00000100
	db 0b00000000
	db 0b00000100
	db 0b00000100
	db 0b00000100
	db 0b01000100
	db 0b00111000
.k:
	db 0b01000000
	db 0b01000000
	db 0b01001000
	db 0b01010000
	db 0b01100000
	db 0b01010000
	db 0b01001000
	db 0b00000000
.l:
	db 0b01100000
	db 0b00100000
	db 0b00100000
	db 0b00100000
	db 0b00100000
	db 0b00100000
	db 0b01110000
	db 0b00000000
.m:
	db 0b00000000
	db 0b00000000
	db 0b01101000
	db 0b01010100
	db 0b01010100
	db 0b01010100
	db 0b01010100
	db 0b00000000
.n:
	db 0b00000000
	db 0b00000000
	db 0b01110000
	db 0b01001000
	db 0b01001000
	db 0b01001000
	db 0b01001000
	db 0b00000000
.o:
	db 0b00000000
	db 0b00000000
	db 0b00111000
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.p:
	db 0b00000000
	db 0b00000000
	db 0b01111000
	db 0b01000100
	db 0b01000100
	db 0b01111000
	db 0b01000000
	db 0b01000000
.q:
	db 0b00000000
	db 0b00000000
	db 0b00111100
	db 0b01000100
	db 0b01000100
	db 0b00111100
	db 0b00000100
	db 0b00000100
.r:
	db 0b00000000
	db 0b00000000
	db 0b01111000
	db 0b01000100
	db 0b01000000
	db 0b01000000
	db 0b01000000
	db 0b00000000
.s:
	db 0b00000000
	db 0b00000000
	db 0b01111000
	db 0b10000000
	db 0b01111000
	db 0b00000100
	db 0b01111000
	db 0b00000000
.t:
	db 0b00010000
	db 0b00010000
	db 0b01111100
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00001000
	db 0b00000000
.u:
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b01000100
	db 0b01000100
	db 0b01000100
	db 0b00111000
	db 0b00000000
.v:
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b01000100
	db 0b01000100
	db 0b00101000
	db 0b00010000
	db 0b00000000
.w:
	db 0b00000000
	db 0b00000000
	db 0b00000000
	db 0b01000100
	db 0b01010100
	db 0b01010100
	db 0b00101000
	db 0b00000000
.x:
	db 0b00000000
	db 0b00000000
	db 0b01000100
	db 0b00101000
	db 0b00010000
	db 0b00101000
	db 0b01000100
	db 0b00000000
.y:
	db 0b00000000
	db 0b00000000
	db 0b01000100
	db 0b01000100
	db 0b00111100
	db 0b00000100
	db 0b01000100
	db 0b00111000
.z:
	db 0b00000000
	db 0b00000000
	db 0b01111100
	db 0b00001000
	db 0b00010000
	db 0b00100000
	db 0b01111100
	db 0b00000000
.left_curly_bracket:
	db 0b00010000
	db 0b00100000
	db 0b00100000
	db 0b01000000
	db 0b00100000
	db 0b00100000
	db 0b00010000
	db 0b00000000
.pipe:
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00010000
	db 0b00000000
.right_curly_bracket:
	db 0b01000000
	db 0b00100000
	db 0b00100000
	db 0b00010000
	db 0b00100000
	db 0b00100000
	db 0b01000000
	db 0b00000000
.tilde:
	db 0b00000000
	db 0b00000000
	db 0b00100000
	db 0b01010100
	db 0b00001000
	db 0b00000000
	db 0b00000000
	db 0b00000000
.unknown:
	db 0b11111111
	db 0b11101111
	db 0b11101111
	db 0b10000011
	db 0b11101111
	db 0b11101111
	db 0b11101111
	db 0b11111111




font_scaler:

	push rbp
	push rdi
	push rsi
	push rdx
	push rcx
	push rbx
	push rax
	push r8
	push r9
	push r10 ; track the x
	push r11 ; track the y
	push r12 
	push r13 
	push r14 
	push r15
	; r8 always stores the left x pixel
	; r9 stores the current y pixel
	

.letter_loop:
	xor rbp,rbp
	mov bpl,byte [r11]
	sub rbp,32
	shl rbp,3
	add rbp,SCHIZOFONT

	mov r12,8
.row_loop:
	mov r8,[rsp+56]
	mov bl, byte [rbp]
	mov r14,8
;	imul r14,r10
.col_loop:
	mov r13b,bl
	test r13b, byte 1
	jz .no_pixel

	mov rax,r10
.scale_loop_x:
	mov r15,r10
	push r9
.scale_loop_y:
	push r8
;	mov rbp,r14
;	imul rbp,r10
	add r8,r14



	call set_pixel
	pop r8
	inc r9
	dec r15
	jnz .scale_loop_y
	pop r9
	inc r8
	dec rax
	jnz .scale_loop_x
	jmp .rendered_pixels

.no_pixel:
	add r8,r10

.rendered_pixels:
	shr bl,1
	dec r14
	jnz .col_loop

	inc rbp
	add r9,r10 ; was inc r9
	
	dec r12
	jnz .row_loop

	mov r9,[rsp+48]
	mov r8,[rsp+56]
	mov rbp,8
	imul rbp,r10
	add r8,rbp
	mov [rsp+56],r8
	inc r11
	cmp byte [r11],0
	jnz .letter_loop

	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rax
	pop rbx
	pop rcx
	pop rdx
	pop rsi
	pop rdi
	pop rbp
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
	mov r8d,100
	mov r9d,100
	mov r10,4
	mov r11,.sample_text
	call font_scaler

	call framebuffer_flush	; flush frame to framebuffer
	
	xor dil,dil
	call exit

.sample_text:
	db `THIS IS SAMPLE TEXT!`,0	

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)

