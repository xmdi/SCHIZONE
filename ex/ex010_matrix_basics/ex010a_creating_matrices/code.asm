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

%include "lib/math/matrix/matrix_set_identity.asm"
; void matrix_set_identity(double* {rdi}, uint {rsi}, uint {rdx});

%include "lib/math/matrix/matrix_set_all_values.asm"
; void matrix_set_all_values(double* {rdi}, uint {rsi}, double {xmm0});

%include "lib/math/matrix/matrix_populate.asm"
; void matrix_populate(double* {rdi}, double* {rsi}, uint {rdx}, uint {rcx},
;			 uint {r8}, uint {r9});

%include "lib/mem/memcopy.asm"
; void memcopy(long* {rdi}, long* {rsi}, ulong {rdx});

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

	; print matrix
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,MATRIX		; matrix start address
	mov rdx,4		; 4 rows
	mov rcx,4		; 4 columns
	xor r8,r8		; no extra offsets betwixt elements
	mov r9,print_float	; print without scientific notation
	mov r10,5		; 5 significant figures
	call print_array_float

	; set MATRIX to 4x4 identity matrix
	mov rdi,MATRIX
	mov rsi,4
	mov rdx,4
	call matrix_set_identity

	; print "\nIdentity Matrix=\n"
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,.grammar1	
	mov rdx,.grammar2-.grammar1
	call print_chars

	; print matrix
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,MATRIX		; matrix start address
	mov rdx,4		; 4 rows
	mov rcx,4		; 4 columns
	xor r8,r8		; no extra offsets betwixt elements
	mov r9,print_float	; print without scientific notation
	mov r10,5		; 5 significant figures
	call print_array_float

	; set MATRIX to 4x4 matrix of "pi"
	mov rdi,MATRIX
	mov rsi,16		; 16 elements in total
	movsd xmm0,[PI]
	call matrix_set_all_values

	; print "\nPi Matrix=\n"
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,.grammar2	
	mov rdx,.grammar3-.grammar2
	call print_chars

	; print matrix
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,MATRIX		; matrix start address
	mov rdx,4		; 4 rows
	mov rcx,4		; 4 columns
	xor r8,r8		; no extra offsets betwixt elements
	mov r9,print_float	; print without scientific notation
	mov r10,5		; 5 significant figures
	call print_array_float

	; copy ANOTHER_MATRIX to MATRIX
	mov rdi,MATRIX
	mov rsi,ANOTHER_MATRIX
	mov rdx,16*8		; 128 bytes in total
	call memcopy

	; print "\nCopied Matrix=\n"
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,.grammar3	
	mov rdx,.grammar4-.grammar3
	call print_chars

	; print matrix
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,MATRIX		; matrix start address
	mov rdx,4		; 4 rows
	mov rcx,4		; 4 columns
	xor r8,r8		; no extra offsets betwixt elements
	mov r9,print_float	; print without scientific notation
	mov r10,5		; 5 significant figures
	call print_array_float

	; populate MATRIX from ARRAY_OF_STRUCTS
	mov rdi,MATRIX
	mov rsi,ARRAY_OF_STRUCTS+8	; offset to first value in array
	mov rdx,4
	mov rcx,4
	mov r8,40
	mov r9,8			; no extra offset between columns
	call matrix_populate

	; print "\nPopulated Matrix=\n"
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,.grammar4	
	mov rdx,MATRIX-.grammar4
	call print_chars

	; print matrix
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,MATRIX		; matrix start address
	mov rdx,4		; 4 rows
	mov rcx,4		; 4 columns
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
	db `\nIdentity Matrix=\n`
.grammar2:
	db `\nPi Matrix=\n`
.grammar3:
	db `\nCopied Matrix=\n`
.grammar4:
	db `\nPopulated Matrix=\n`

MATRIX:	; initialize 4x4 matrix to all 420.0
	times 16 dq 420.0

ANOTHER_MATRIX:
	times 4 dq 1.1
	times 4 dq 2.2
	times 4 dq 3.3
	times 4 dq 4.4

PI:
	dq 3.1

ARRAY_OF_STRUCTS:
	db `CAT_____`	; animal ID
	dq 4.0		; number of legs
	dq 1000000.0	; number of hair
	dq 1.5		; height in feet
	dq 2.5		; length in feet
	db `DOG_____`	; animal ID
	dq 4.0		; number of legs
	dq 1000000.0	; number of hair
	dq 2.5		; height in feet
	dq 3.5		; length in feet
	db `BIRD____`	; animal ID
	dq 2.0		; number of legs
	dq 0.0		; number of hair
	dq 0.5		; height in feet
	dq 0.25		; length in feet
	db `BALD_MAN`	; animal ID
	dq 2.0		; number of legs
	dq 0.0		; number of hair
	dq 6.0		; height in feet
	dq 2.0		; length in feet

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
