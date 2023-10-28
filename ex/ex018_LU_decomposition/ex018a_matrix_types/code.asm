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

%include "lib/math/lin_alg/is_upper_triangular.asm"
; bool {rax} is_upper_triangular(double* {rdi}, uint {rsi}, double {xmm0});

%include "lib/math/lin_alg/is_lower_triangular.asm"
; bool {rax} is_lower_triangular(double* {rdi}, uint {rsi}, double {xmm0});

%include "lib/math/lin_alg/is_diagonal.asm"
; bool {rax} is_diagonal(double* {rdi}, uint {rsi}, double {xmm0});

%include "lib/io/print_array_float.asm"
; void print_array_float(int {rdi}, double* {rsi}, int {rdx}, int {rcx}, 
;	int {r8}, void* {r9}, int {r10});

%include "lib/sys/exit.asm"	
; void exit(byte {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; this function checks the types of a matrix in {rbx} and prints stuff out
CHECK_MATRIX_TYPES:

	movsd xmm0,[.tolerance]

	; print out the matrix of interest
	mov rdi,SYS_STDOUT
	mov rsi,rbx
	mov rcx,4
	mov rdx,4
	xor r8,r8
	mov r9,print_float
	mov r10,3
	call print_array_float

	; print `Is this matrix upper-triangular? `
	mov rsi,.is_this_upper_triangular
	mov rdx,33
	call print_chars

	mov rdi,rbx
	mov rsi,4
	call is_upper_triangular
	mov rdi,SYS_STDOUT
	test rax,rax
	jz .not_upper_triangular
	mov rsi,.yes
	mov rdx,4
	call print_chars
	jmp .check_lower_triangular
.not_upper_triangular:
	mov rsi,.no
	mov rdx,7
	call print_chars

.check_lower_triangular:

	; print `Is this matrix lower-triangular? `
	mov rsi,.is_this_lower_triangular
	mov rdx,33
	call print_chars

	mov rdi,rbx
	mov rsi,4
	call is_lower_triangular
	mov rdi,SYS_STDOUT
	test rax,rax
	jz .not_lower_triangular
	mov rsi,.yes
	mov rdx,4
	call print_chars
	jmp .check_diagonal
.not_lower_triangular:
	mov rsi,.no
	mov rdx,7
	call print_chars
.check_diagonal:
	; print `Is this matrix diagonal? `
	mov rsi,.is_this_diagonal
	mov rdx,25
	call print_chars

	mov rdi,rbx
	mov rsi,4
	call is_diagonal
	mov rdi,SYS_STDOUT
	test rax,rax
	jz .not_diagonal
	mov rsi,.yes
	mov rdx,4
	call print_chars
	jmp .done
.not_diagonal:
	mov rsi,.no
	mov rdx,7
	call print_chars
.done:
	ret

.is_this_upper_triangular:
	db `Is this matrix upper-triangular? `
.is_this_lower_triangular:
	db `Is this matrix lower-triangular? `
.is_this_diagonal:
	db `Is this matrix diagonal? `
.yes:
	db `yup\n`
.no:
	db `no lol\n`
.tolerance:
	dq 0.00001

START:

	mov rbx,.matrix_1
	call CHECK_MATRIX_TYPES

	; print newline
	mov rdi,SYS_STDOUT
	mov rsi,.newline
	mov rdx,1
	call print_chars

	mov rbx,.matrix_2
	call CHECK_MATRIX_TYPES

	; print newline
	mov rdi,SYS_STDOUT
	mov rsi,.newline
	mov rdx,1
	call print_chars

	mov rbx,.matrix_3
	call CHECK_MATRIX_TYPES
	
	; print newline
	mov rdi,SYS_STDOUT
	mov rsi,.newline
	mov rdx,1
	call print_chars

	mov rbx,.matrix_4
	call CHECK_MATRIX_TYPES

	; flush print buffer
	call print_buffer_flush

	; exit 
	xor dil,dil
	call exit	

.newline:
	db `\n`

.matrix_1: ; fully populated pi matrix
	times 16 dq 3.13

.matrix_2: ; upper-triangular pi matrix
	times 4 dq 3.13
	dq 0.0 
	times 3 dq 3.13
	times 2 dq 0.0 
	times 2 dq 3.13
	times 3 dq 0.0
	dq 3.13

.matrix_3: ; lower triangular pi matrix
	dq 3.13
	times 3 dq 0.0
	times 2 dq 3.13
	times 2 dq 0.0
	times 3 dq 3.13
	dq 0.0
	times 4 dq 3.13

.matrix_4: ; diagonal pi matrix
	dq 3.13
	times 4 dq 0.0
	dq 3.13
	times 4 dq 0.0
	dq 3.13
	times 4 dq 0.0
	dq 3.13

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
