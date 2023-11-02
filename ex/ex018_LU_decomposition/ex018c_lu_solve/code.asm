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

%include "lib/math/lin_alg/lu_decomposition.asm"
; void LU_decomposition(double* {rdi}, uint {rsi});

%include "lib/math/lin_alg/forward_substitution.asm"
; bool forward_substitution(double* {rdi}, double* {rsi}, double* {rdx}, uint {rcx});

%include "lib/math/lin_alg/backward_substitution.asm"
; bool backward_substitution(double* {rdi}, double* {rsi}, double* {rdx}, uint {rcx});

%include "lib/math/lin_alg/copy_upper_triangle.asm"
; void copy_upper_triangle(double* {rdi}, double* {rsi}, uint {rdx});

%include "lib/math/lin_alg/copy_lower_triangle.asm"
; void copy_lower_triangle(double* {rdi}, double* {rsi}, uint {rdx});

%include "lib/math/lin_alg/copy_diagonal.asm"
; void copy_diagonal(double* {rdi}, double* {rsi}, uint {rdx});

%include "lib/math/lin_alg/set_identity.asm"
; void set_identity(double* {rdi}, uint {rsi});

%include "lib/sys/exit.asm"	
; void exit(byte {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:

	; print `Trying to solve Ax=b:\n`
	mov rdi,SYS_STDOUT
	mov rsi,.grammar1
	mov rdx,22
	call print_chars

	; print `\nA=\n`
	mov rsi,.grammar2
	mov rdx,4
	call print_chars

	; print original A matrix
	mov rsi,.A
	mov rdx,3
	mov rcx,3
	xor r8,r8
	mov r9,print_float
	mov r10,5
	call print_array_float

	; print `\nb=\n`
	mov rsi,.grammar3
	mov rdx,4
	call print_chars

	; print RHS b-vector
	mov rsi,.b
	mov rdx,3
	mov rcx,1
	xor r8,r8
	mov r9,print_float
	mov r10,5
	call print_array_float

	; compute the LU decomposition in-place
	mov rdi,.A
	mov rsi,3
	call lu_decomposition
	
	; print `\nA decomposed into LU in-place:\n`
	mov rdi,SYS_STDOUT
	mov rsi,.grammar4
	mov rdx,32
	call print_chars

	; print decomposed matrix
	mov rsi,.A
	mov rdx,3
	mov rcx,3
	xor r8,r8
	mov r9,print_float
	mov r10,5
	call print_array_float

	; copy upper half of decomposed matrix into its own memory
	; (ultimately unnecessary, but just to show the process)
	mov rdi,.U
	mov rsi,.A
	mov rdx,3
	call copy_upper_triangle

	; print `\nU=\n`
	mov rdi,SYS_STDOUT
	mov rsi,.grammar5
	mov rdx,4
	call print_chars

	; print U matrix
	mov rsi,.U
	mov rdx,3
	mov rcx,3
	xor r8,r8
	mov r9,print_float
	mov r10,5
	call print_array_float

	; copy lower half of decomposed matrix into its own memory
	; (ultimately unnecessary, but just to show the process)
	mov rdi,.L
	mov rsi,.A
	mov rdx,3
	call copy_lower_triangle

	; drag the diagonal from an identity matrix into L
	; (ultimately unnecessary, but just to show the process)
	mov rdi,.A	;	overwrite A matrix because I'm lazy
	mov rsi,3
	call set_identity

	mov rdi,.L
	mov rsi,.A
	mov rdx,3
	call copy_diagonal

	; print `\nL=\n`
	mov rdi,SYS_STDOUT
	mov rsi,.grammar6
	mov rdx,4
	call print_chars

	; print L matrix
	mov rsi,.L
	mov rdx,3
	mov rcx,3
	xor r8,r8
	mov r9,print_float
	mov r10,5
	call print_array_float

	; print `\nNew problem is Ax=L(Ux)=b. Using forward substitution to find (Ux):\n`
	mov rsi,.grammar7
	mov rdx,69
	call print_chars

	; use forward subsitution to find (Ux) from Ax=L(Ux)=b
	mov rdi,.Ux
	mov rsi,.L
	mov rdx,.b
	xor r8,r8
	mov rcx,3
	call forward_substitution

	; print `\n(Ux)=\n`
	mov rdi,SYS_STDOUT
	mov rsi,.grammar8
	mov rdx,7
	call print_chars

	; print (Ux) vector
	mov rsi,.Ux
	mov rdx,3
	mov rcx,1
	xor r8,r8
	mov r9,print_float
	mov r10,5
	call print_array_float

	; print `\nNew problem is Ux=(Ux). Using backward substitution to find (x):\n`
	mov rsi,.grammar9
	mov rdx,64
	call print_chars

	; use backward subsitution to find (x) from U(x)=(Ux) (from above)
	mov rdi,.x
	mov rsi,.U
	mov rdx,.Ux
	mov rcx,3
	xor r8,r8
	call backward_substitution
	
	; print `\nx=\n`
	mov rdi,SYS_STDOUT
	mov rsi,.grammar10
	mov rdx,4
	call print_chars

	; print resultant (x)
	mov rsi,.x
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


.A:	; left-hand-side matrix
	dq -13.00, -6.66, 4.20
	dq -6.90, 13.37, 17.76
	dq 14.88, 42.00, 7.77

.b: ; right-hand-side vector
	dq 1.23, -4.56, 7.89

.L: ; space for lower-triangular matrix
	times 9 dq 0.00

.U: ; space for upper-triangular matrix
	times 9 dq 0.00

.Ux: ; space for solved (intermediate) unknown vector
	times 3 dq 0.00

.x: ; space for solved unknown vector
	times 3 dq 0.00

.grammar1:
	db `Trying to solve Ax=b:\n`
.grammar2:
	db `\nA=\n`
.grammar3:
	db `\nb=\n`
.grammar4:
	db `\nA decomposed into LU in-place:\n`
.grammar5:
	db `\nU=\n`
.grammar6:
	db `\nL=\n`
.grammar7:
	db `\nNew problem is Ax=L(Ux)=b. Using forward substitution to find (Ux):\n`
.grammar8:
	db `\n(Ux)=\n`
.grammar9:
	db `\nNew problem is Ux=(Ux). Using backward substitution to find x:\n`
.grammar10:
	db `\nx=\n`

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
