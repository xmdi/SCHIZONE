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

%include "lib/math/matrix/matrix_add.asm"
; void matrix_add(double* {rdi}, double* {rsi}, double* {rdx}, uint {rcx});

%include "lib/math/matrix/matrix_add_in_place.asm"
; void matrix_add_in_place(double* {rdi}, double* {rsi}, long {rdx});

%include "lib/math/matrix/matrix_subtract.asm"
; void matrix_subtract(double* {rdi}, double* {rsi}, double* {rdx}, uint {rcx});

%include "lib/math/matrix/matrix_subtract_in_place.asm"
; void matrix_subtract_in_place(double* {rdi}, double* {rsi}, long {rdx});

%include "lib/math/matrix/matrix_scale.asm"
; void matrix_scale(double* {rdi}, double* {rsi}, uint {rdx}, double {xmm0});

%include "lib/math/matrix/matrix_scale_in_place.asm"
; void matrix_scale_in_place(double* {rdi}, long {rsi}, double {xmm0});

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

	; print "\nInitial Matrix A=\n"
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,.grammar0	
	mov rdx,.grammar1-.grammar0
	call print_chars

	; print initial matrix A
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,MATRIX_A	; matrix start address
	mov rdx,3		; 3 rows
	mov rcx,3		; 3 columns
	xor r8,r8		; no extra offsets betwixt elements
	mov r9,print_float	; print without scientific notation
	mov r10,5		; 5 significant figures
	call print_array_float

	; print "\nInitial Matrix B=\n"
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,.grammar1	
	mov rdx,.grammar2-.grammar1
	call print_chars

	; print initial matrix B
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,MATRIX_B	; matrix start address
	mov rdx,3		; 3 rows
	mov rcx,3		; 3 columns
	xor r8,r8		; no extra offsets betwixt elements
	mov r9,print_float	; print without scientific notation
	mov r10,5		; 5 significant figures
	call print_array_float

	; print "\nInitial Matrix C=\n"
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,.grammar2	
	mov rdx,.grammar3-.grammar2
	call print_chars

	; print initial matrix C
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,MATRIX_C	; matrix start address
	mov rdx,3		; 3 rows
	mov rcx,3		; 3 columns
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
	db `\nInitial Matrix A=\n`
.grammar1:
	db `\nInitial Matrix B=\n`
.grammar2:
	db `\nInitial Matrix C=\n`
.grammar3:
	db `\nMatrix C*=2.0:\n`
.grammar4:
	db `\nMatrix C=A*3.0:\n`
.grammar5:
	db `\nMatrix A+=C:\n`
.grammar6:
	db `\nMatrix B-=C:\n`
.grammar7:
	db `\nMatrix C=A+B:\n`
.grammar8:
	db `\nMatrix C=A-B:\n`
.grammar9:
	db `\nMatrix C=A*B:\n`

MATRIX_A:
	times 9 dq 1.0

MATRIX_B:
	times 9 dq -2.0

MATRIX_C:
	times 9 dq 0.0

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
