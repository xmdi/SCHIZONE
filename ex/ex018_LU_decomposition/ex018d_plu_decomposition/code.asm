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
; void print_array_float(int {rdi}, double* {rsi}, int {rdx}, int {rcx}, 
;	int {r8}, void* {r9}, int {r10});

%include "lib/io/print_array_int.asm"
; void print_array_int(int {rdi}, int* {rsi}, int {rdx}, int {rcx}, int {r8}
;	void* {r9});

%include "lib/math/lin_alg/plu_solve.asm"
; void plu_solve(double* {rdi}, double* {rsi}, double* {rdx}, uint {rcx}, 
;	uint* {r8});

%include "lib/mem/memcopy.asm"
; void memcopy(long* {rdi}, long* {rsi}, ulong {rdx});

%include "lib/math/matrix/matrix_subtract_in_place.asm"
; void matrix_subtract_in_place(double* {rdi}, double* {rsi}, long {rdx});

%include "lib/math/matrix/matrix_multiply.asm"
; void matrix_multiply(double* {rdi}, double* {rsi}, double* {rdx}, uint {rcx}
;	uint {r8}, uint {r9});

%include "lib/sys/exit.asm"	
; void exit(byte {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:

	; Let's save a copy of A & b so we can check our work later.
	; This is because our in-place LU destroys the input matrix A
	; and our substitution algorithms destroy RHS vector b.
	; This is unnecessary in a real implementation.

	mov rdi,.A_copy
	mov rsi,.A
	mov rdx,8*10*10
	call memcopy

	mov rdi,.b_copy
	mov rsi,.b
	mov rdx,8*10
	call memcopy

	; print `Trying to solve Ax=b:\n`
	mov rdi,SYS_STDOUT
	mov rsi,.grammar1
	mov rdx,22
	call print_chars

	; print `\nA=\n`
	mov rdi,SYS_STDOUT
	mov rsi,.grammar2
	mov rdx,4
	call print_chars

	; print original A matrix
	mov rdi,SYS_STDOUT
	mov rsi,.A
	mov rdx,10
	mov rcx,10
	xor r8,r8
	mov r9,print_float
	mov r10,5
	call print_array_float

	; print `\nb=\n`
	mov rdi,SYS_STDOUT
	mov rsi,.grammar3
	mov rdx,4
	call print_chars

	; print RHS b-vector
	mov rdi,SYS_STDOUT
	mov rsi,.b	
	mov rdx,10
	mov rcx,1
	xor r8,r8
	mov r9,print_float
	mov r10,5
	call print_array_float

	; solve the system using pivotless LU decomposition
	mov rdi,.x
	mov rsi,.A
	mov rdx,.b
	mov rcx,10
	mov r8,.P
	call plu_solve
	
	; print `\nx=\n`
	mov rdi,SYS_STDOUT
	mov rsi,.grammar4
	mov rdx,4
	call print_chars

	; print resultant (x)
	mov rdi,SYS_STDOUT
	mov rsi,.x
	mov rdx,10
	mov rcx,1
	xor r8,r8
	mov r9,print_float
	mov r10,5
	call print_array_float

	; print `\nP=\n`
	mov rdi,SYS_STDOUT
	mov rsi,.grammar6
	mov rdx,4
	call print_chars

	; print permutation vector P
	mov rdi,SYS_STDOUT
	mov rsi,.P
	mov rdx,10
	mov rcx,1
	xor r8,r8
	mov r9,print_int_d
	call print_array_int

	; compute A_copy*x-b_copy to check our error
	; (should be 0.00)
	mov rdi,.Ax_minus_b
	mov rsi,.A_copy
	mov rdx,.x
	mov rcx,10
	mov r8,1
	mov r9,10
	call matrix_multiply

	mov rdi,.Ax_minus_b
	mov rsi,.b_copy
	mov rdx,10
	call matrix_subtract_in_place

	; print `\nAx-b=\n`
	mov rdi,SYS_STDOUT
	mov rsi,.grammar5
	mov rdx,7
	call print_chars

	; print the error (Ax-b)
	mov rdi,SYS_STDOUT
	mov rsi,.Ax_minus_b
	mov rdx,10
	mov rcx,1
	xor r8,r8
	mov r9,print_float
	mov r10,5
	call print_array_float
	
	; flush print buffer
	mov rdi,SYS_STDOUT
	call print_buffer_flush

	; exit
	xor rdi,rdi
	call exit

.A:	; left-hand-side matrix
	dq 0.315830,0.718678,0.643784,0.264561,0.026255,0.012253,0.182901,0.746122,0.778747,0.616386
	dq 0.934982,0.772819,0.710261,0.529634,0.729353,0.800348,0.076543,0.311112,0.825929,0.628582
	dq 0.725809,0.578045,0.886985,0.436040,0.227404,0.910350,0.418371,0.859447,0.486491,0.104371
	dq 0.393253,0.082315,0.070661,0.401792,0.503068,0.168260,0.897839,0.154161,0.140111,0.969764
	dq 0.181329,0.872779,0.990957,0.404892,0.557183,0.161105,0.261683,0.875127,0.502225,0.423103
	dq 0.071594,0.469551,0.453939,0.362485,0.380149,0.562559,0.556261,0.076676,0.946100,0.853400
	dq 0.968693,0.183503,0.028800,0.884395,0.135946,0.766381,0.828997,0.515065,0.029500,0.055620
	dq 0.977877,0.414485,0.106278,0.231908,0.622803,0.062961,0.566598,0.404039,0.757158,0.619621
	dq 0.019140,0.426698,0.744837,0.172939,0.345544,0.912820,0.607630,0.828331,0.824672,0.431111
	dq 0.893784,0.131251,0.502070,0.843047,0.936461,0.241379,0.510511,0.013705,0.348640,0.267587

.A_copy:; let's save a copy of A just so we can check our work after
	; destroying A with in-place LU decomposition 
	; (unnecessary, obviously)
	times 100 dq 0.00

.b: ; right-hand-side vector
	dq 0.1575,0.5914,0.5803,0.5691,0.7833,0.7300,0.1439,0.6159,0.9052,0.8420

.b_copy:; let's save a copy of B just so we can check our work after
	; destroying A with in-place LU decomposition 
	; (unnecesary, obviously)
	times 10 dq 0.00

.x: ; space for solved unknown vector
	times 10 dq 0.00

.P: ; space for permuation vector
	times 10 dq 0.00

.Ax_minus_b: ; space to check our work (unnecessary, obviously)
	times 10 dq 0.00

.grammar1:
	db `Trying to solve Ax=b:\n`
.grammar2:
	db `\nA=\n`
.grammar3:
	db `\nb=\n`
.grammar4:
	db `\nx=\n`
.grammar5:
	db `\nAx-b=\n`
.grammar6:
	db `\nP=\n`
.
END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
