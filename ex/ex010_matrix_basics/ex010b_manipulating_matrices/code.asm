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

%include "lib/math/matrix/matrix_insert_row.asm"
; void matrix_insert_row(double* {rdi}, double* {rsi}, uint {rdx}, uint {rcx});

%include "lib/math/matrix/matrix_extract_row.asm"
; void matrix_extract_row(double* {rdi}, double* {rsi}, uint {rdx}, uint {rcx});

%include "lib/math/matrix/matrix_insert_column.asm"
; void matrix_insert_column(double* {rdi}, double* {rsi}, uint {rdx},
;	uint {rcx}, uint {r8});

%include "lib/math/matrix/matrix_extract_column.asm"
; void matrix_extract_column(double* {rdi}, double* {rsi}, uint {rdx}, 
;	uint {rcx}, uint {r8});

%include "lib/math/matrix/matrix_transpose.asm"
; void matrix_transpose(double* {rdi}, double* {rsi}, uint {rdx}, uint {rcx});

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

	; print "\nInitial Matrix=\n"
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,.grammar0	
	mov rdx,.grammar1-.grammar0
	call print_chars

	; print initial matrix
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,MATRIX		; matrix start address
	mov rdx,4		; 4 rows
	mov rcx,3		; 3 columns
	xor r8,r8		; no extra offsets betwixt elements
	mov r9,print_float	; print without scientific notation
	mov r10,5		; 5 significant figures
	call print_array_float

	; print "\nInitial Row Vector=\n"
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,.grammar1	
	mov rdx,.grammar2-.grammar1
	call print_chars

	; print initial row vector
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,VECTOR_3	; vector start address
	mov rdx,1		; 1 row
	mov rcx,3		; 3 columns
	xor r8,r8		; no extra offsets betwixt elements
	mov r9,print_float	; print without scientific notation
	mov r10,5		; 5 significant figures
	call print_array_float

	; print "\nInitial Column Vector=\n"
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,.grammar2	
	mov rdx,.grammar3-.grammar2
	call print_chars

	; print initial column vector
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,VECTOR_4	; vector start address
	mov rdx,4		; 4 rows
	mov rcx,1		; 1 columns
	xor r8,r8		; no extra offsets betwixt elements
	mov r9,print_float	; print without scientific notation
	mov r10,5		; 5 significant figures
	call print_array_float

	; print "\nMatrix with Row Inserted=\n"
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,.grammar3
	mov rdx,.grammar4-.grammar3
	call print_chars

	; insert row into 3rd row of matrix
	mov rdi,MATRIX		; destination array
	mov rsi,VECTOR_3	; source vector
	mov rdx,3		; 3 columns
	mov rcx,2		; insert into row 2, aka the 3rd row
	call matrix_insert_row

	; print initial matrix
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,MATRIX		; matrix start address
	mov rdx,4		; 4 rows
	mov rcx,3		; 3 columns
	xor r8,r8		; no extra offsets betwixt elements
	mov r9,print_float	; print without scientific notation
	mov r10,5		; 5 significant figures
	call print_array_float

	; print "\nMatrix with Column Inserted=\n"
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,.grammar4
	mov rdx,.grammar5-.grammar4
	call print_chars

	; insert column into 2nd column of matrix
	mov rdi,MATRIX		; destination array
	mov rsi,VECTOR_4	; source vector
	mov rdx,4		; 4 rows
	mov rcx,3		; 3 columns
	mov r8,1		; insert into column 1, aka 2nd column
	call matrix_insert_column

	; print initial matrix
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,MATRIX		; matrix start address
	mov rdx,4		; 4 rows
	mov rcx,3		; 3 columns
	xor r8,r8		; no extra offsets betwixt elements
	mov r9,print_float	; print without scientific notation
	mov r10,5		; 5 significant figures
	call print_array_float

	; print "\nMatrix Transposed=\n"
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,.grammar5
	mov rdx,.grammar6-.grammar5
	call print_chars

	; transpose matrix
	mov rdi,MATRIX_TRANSPOSED	; destination array
	mov rsi,MATRIX	; source vector
	mov rdx,4		; 4 rows
	mov rcx,3		; 3 columns
	call matrix_transpose

	; print transposed matrix
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,MATRIX_TRANSPOSED	; matrix start address
	mov rdx,3		; 3 rows
	mov rcx,4		; 4 columns
	xor r8,r8		; no extra offsets betwixt elements
	mov r9,print_float	; print without scientific notation
	mov r10,5		; 5 significant figures
	call print_array_float

	; print "\nRow Vector Extracted=\n"
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,.grammar6
	mov rdx,.grammar7-.grammar6
	call print_chars

	; extract 1st row to vector
	mov rdi,VECTOR_4	; destination vector
	mov rsi,MATRIX_TRANSPOSED	; source matrix
	mov rdx,4		; 4 columns
	mov rcx,0		; row 0, aka 1st row
	call matrix_extract_row

	; print extracted row vectore
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,VECTOR_4	; vector start address
	mov rdx,1		; 1 rows
	mov rcx,4		; 4 columns
	xor r8,r8		; no extra offsets betwixt elements
	mov r9,print_float	; print without scientific notation
	mov r10,5		; 5 significant figures
	call print_array_float

	; print "\nColumn Vector Extracted=\n"
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,.grammar7
	mov rdx,MATRIX-.grammar7
	call print_chars

	; extract 1st column to vector
	mov rdi,VECTOR_4	; destination vector
	mov rsi,MATRIX_TRANSPOSED	; source matrix
	mov rdx,3		; 3 rows
	mov rcx,4		; 4 columns
	mov r8,0		; row 0, aka 1st row
	call matrix_extract_column

	; print extracted row vectore
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,VECTOR_4	; vector start address
	mov rdx,3		; 3 rows
	mov rcx,1		; 1 columns
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
	db `\nInitial Matrix=\n`
.grammar1:
	db `\nInitial Row Vectorx=\n`
.grammar2:
	db `\nInitial Column Vector=\n`
.grammar3:
	db `\nMatrix with Row 2 Inserted=\n`
.grammar4:
	db `\nMatrix with Column 1 Inserted=\n`
.grammar5:
	db `\nMatrix Transposed=\n`
.grammar6:
	db `\nRow 0 Vector Extracted=\n`
.grammar7:
	db `\nColumn 0 Vector Extracted=\n`

MATRIX:	; initialize 4x3 matrix to all 0.0
	times 12 dq 0.0

MATRIX_TRANSPOSED:
	times 12 dq 0.0

VECTOR_3:
	times 3 dq 777.77

VECTOR_4:
	times 4 dq 666.66

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
