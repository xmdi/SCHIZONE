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

%include "lib/math/integration/trapezoidal_method.asm"
; double {xmm0} trapezoidal_method(void* {rdi}, double {xmm0}, double {xmm1}, double {xmm2});

%include "lib/io/print_float.asm"
; void print_float(int {rdi}, double {xmm0}, int {rsi});

%include "lib/io/print_int_d.asm"
; void print_int_d(int {rdi}, long {rsi});

%include "lib/sys/exit.asm"
; void exit(char {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

FUNC:	; input and output in {xmm0}
	; y=-4x^3+3x^2+x/2-51
	
	sub rsp,32
	movdqu [rsp+0],xmm1
	movdqu [rsp+16],xmm2
	
	movsd xmm1,xmm0
	mulsd xmm1,xmm1
	movsd xmm2,xmm1
	mulsd xmm2,xmm0
	mulsd xmm2,[.neg_four]
	mulsd xmm1,[.three]
	mulsd xmm0,[.half]
	addsd xmm0,xmm1
	addsd xmm0,xmm2
	subsd xmm0,[.fifty_one]
	
	movdqu xmm1,[rsp+0]
	movdqu xmm2,[rsp+16]
	add rsp,32
	
	ret
	
.neg_four:
	dq -4.0
.three:
	dq 3.0
.half:
	dq 0.5
.fifty_one:
	dq 51.0

START:

	mov rdi,SYS_STDOUT
	mov rsi,.integral
	mov rdx,30
	call print_chars

	mov r8,1

.loop:
	mov rdi,SYS_STDOUT
	mov rsi,.grammar
	mov rdx,7
	call print_chars
	mov rsi,r8
	call print_int_d
	mov rsi,.grammar+6
	mov rdx,17
	call print_chars

	movsd xmm0,[.lower_bound]
	movsd xmm1,[.upper_bound]
	mov rsi,r8
	mov rdi,FUNC
	call trapezoidal_method

	mov rdi,SYS_STDOUT
	mov rsi,6
	call print_float
	mov rsi,.grammar+23
	mov rdx,1
	call print_chars

	inc r8	
	cmp r8,25			; NUMBER OF STEP CASES TO RUN
	jbe .loop

	call print_buffer_flush

	xor dil,dil
	call exit

.lower_bound:
	dq -5.0
.upper_bound:
	dq 5.0

.grammar:
	db `Steps: Estimated Area: \n`
.integral:
	db `function: y=-4x^3+3x^2+x/2-51\n`
END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
