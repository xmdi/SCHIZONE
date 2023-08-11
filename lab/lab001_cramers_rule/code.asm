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

%include "lib/io/print_array_float.asm"	
; void print_array_float(int {rdi}, int* {rsi}, int {rdx}, int {rcx}, int {r8}
;	void* {r9}, int {r10});

%include "lib/mem/memcopy.asm"	
; void memcopy(long* {rdi}, long* {rsi}, ulong {rdx});

%include "lib/math/matrix/matrix_insert_column.asm"
; void matrix_insert_column(double* {rdi}, double* {rsi}, uint {rdx}, 
;		uint {rcx}, uint {r8});

%include "lib/sys/exit.asm"	
; void exit(byte {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; double {xmm0} DET_3x3(double* {rdi});
;	Returns the determinant of the 3x3 dp-fp matrix starting at {rdi}.
;	Violates calling convention by clobbering {xmm1}.	
DET_3x3:
	movsd xmm1,[rdi+0]	; a	
	mulsd xmm1,[rdi+32]	; ae	
	mulsd xmm1,[rdi+64]	; aei	
	movsd xmm0,xmm1
	movsd xmm1,[rdi+8]	; b	
	mulsd xmm1,[rdi+40]	; bf	
	mulsd xmm1,[rdi+48]	; bfg	
	addsd xmm0,xmm1
	movsd xmm1,[rdi+16]	; c	
	mulsd xmm1,[rdi+24]	; cd	
	mulsd xmm1,[rdi+56]	; cdh	
	addsd xmm0,xmm1
	movsd xmm1,[rdi+16]	; c	
	mulsd xmm1,[rdi+32]	; ce	
	mulsd xmm1,[rdi+48]	; ceg	
	subsd xmm0,xmm1
	movsd xmm1,[rdi+8]	; b	
	mulsd xmm1,[rdi+24]	; bd	
	mulsd xmm1,[rdi+64]	; bdi	
	subsd xmm0,xmm1
	movsd xmm1,[rdi+0]	; a	
	mulsd xmm1,[rdi+40]	; af	
	mulsd xmm1,[rdi+56]	; afh	
	subsd xmm0,xmm1

	ret

START:
	
	; compute the det(A) for the original matrix, A
	mov rdi,A
	call DET_3x3	; puts into {xmm0} the det(A)
	movsd xmm15,xmm0	; {xmm15}=det(A)

	; generate A1 (A with b for column 1)
	mov rdi,Ai
	mov rsi,A
	mov rdx,72
	call memcopy	; Ai now contains A
	mov rdi,Ai	
	mov rsi,b
	mov rdx,3
	mov rcx,3
	mov r8,0
	call matrix_insert_column ; Ai now contains A1
	mov rdi,Ai
	call DET_3x3	; {xmm0} contains det(A1)
	divsd xmm0,xmm15
	movsd [x+0],xmm0

	; generate A2 (A with b for column 2)
	mov rdi,Ai
	mov rsi,A
	mov rdx,72
	call memcopy	; Ai now contains A
	mov rdi,Ai	
	mov rsi,b
	mov rdx,3
	mov rcx,3
	mov r8,1
	call matrix_insert_column ; Ai now contains A2
	mov rdi,Ai
	call DET_3x3	; {xmm0} contains det(A2)
	divsd xmm0,xmm15
	movsd [x+8],xmm0

	; generate A3 (A with b for column 3)
	mov rdi,Ai
	mov rsi,A
	mov rdx,72
	call memcopy	; Ai now contains A
	mov rdi,Ai	
	mov rsi,b
	mov rdx,3
	mov rcx,3
	mov r8,2
	call matrix_insert_column ; Ai now contains A3
	mov rdi,Ai
	call DET_3x3	; {xmm0} contains det(A3)
	divsd xmm0,xmm15
	movsd [x+16],xmm0

	; print x vector
	mov rdi,SYS_STDOUT
	mov rsi,x
	mov rdx,3
	mov rcx,1
	xor r8,r8
	mov r9,print_float
	mov r10,5
	call print_array_float
	
	; flush print buffer
	call print_buffer_flush

	; exit
	xor dil,dil
	call exit	

A:
	dq 0.5, -0.866, 0.0
	dq 0.866, 0.5, 0.0
	dq 0.0, 0.866, 1.0
Ai:
	times 9 dq 0.0
b:
	dq 0.0, 100.0, 0.0	
x:
	times 3 dq 0.0

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
