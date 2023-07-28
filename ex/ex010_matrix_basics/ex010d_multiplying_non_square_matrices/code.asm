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

%include "lib/math/rand/rand_float_array.asm"
; void rand_float_array(double {xmm0}, double {xmm1}, double* {rdi},
;			int {rsi}, int {rdx});

%include "lib/math/matrix/matrix_multiply.asm"
; void matrix_multiply(double* {rdi}, double* {rsi}, double* {rdx}, uint {rcx}
;	uint {r8}, uint {r9});

%include "lib/io/print_array_float.asm"
; void print_array_float(int {rdi}, double* {rsi}, int {rdx}, int {rcx}, 
;	int {r8}, void* {r9}, int {r10});

%include "lib/io/print_chars.asm"
; void print_chars(int {rdi}, char* {rsi}, int {rdx});

%include "lib/sys/exit.asm"	
; void exit(byte {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:
	
	; generate random 5x4 matrix A
	mov rax,-10
	cvtsi2sd xmm0,rax	; lower bound
	mov rax,10
	cvtsi2sd xmm1,rax	; upper bound
	mov rdi,MATRIX_A	; matrix A
	xor rsi,rsi		; no extra offset between elements
	mov rdx,20		; 20 double-precision floats
	call rand_float_array

	; generate random 4x6 matrix B
	mov rax,-10
	cvtsi2sd xmm0,rax	; lower bound
	mov rax,10
	cvtsi2sd xmm1,rax	; upper bound
	mov rdi,MATRIX_B	; matrix B
	xor rsi,rsi		; no extra offset between elements
	mov rdx,24		; 24 double-precision floats
	call rand_float_array

	; print "\nA="
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,.grammar0	
	mov rdx,3
	call print_chars

	; print initial matrix A
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,MATRIX_A	; matrix start address
	mov rdx,5		; 5 rows
	mov rcx,4		; 4 columns
	xor r8,r8		; no extra offsets betwixt elements
	mov r9,print_float	; print without scientific notation
	mov r10,5		; 5 significant figures
	call print_array_float

	; print "\nB="
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,.grammar1	
	mov rdx,3
	call print_chars

	; print initial matrix B
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,MATRIX_B	; matrix start address
	mov rdx,4		; 4 rows
	mov rcx,6		; 6 columns
	xor r8,r8		; no extra offsets betwixt elements
	mov r9,print_float	; print without scientific notation
	mov r10,5		; 5 significant figures
	call print_array_float

	; print "\nC=A*B:\n"
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,.grammar2
	mov rdx,MATRIX_A-.grammar2
	call print_chars
	
;	call print_buffer_flush
	
	; set matrix C to A*B
	mov rdi,MATRIX_C
	mov rsi,MATRIX_A
	mov rdx,MATRIX_B
	mov rcx,5
	mov r8,6
	mov r9,4
	call matrix_multiply

	; print new matrix C
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,MATRIX_C	; matrix start address
	mov rdx,5		; 5 rows
	mov rcx,6		; 6 columns
	xor r8,r8		; no extra offsets betwixt elements
	mov r9,print_float	; print without scientific notation
	mov r10,5		; 5 significant figures
	call print_array_float

	; flush print buffer
	call print_buffer_flush

	; exit
	xor dil,dil
	call exit	

.grammar0:
	db `\nA=`
.grammar1:
	db `\nB=`
.grammar2:
	db `\nC=A*B:\n`

MATRIX_A:	; space for 5x4 matrix
	times 20 dq 0

MATRIX_B:	; space for 4x6 matrix
	times 24 dq 0

MATRIX_C:	; space for 5x6 matrix
	times 30 dq 0 

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
