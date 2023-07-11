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

%include "lib/math/rand/rand_int_array.asm"
; void rand_int_array(long* {rdi}, int {rsi}, uint {rdx}, 
;	signed long {rcx}, signed long {r8});

%include "lib/io/print_int_d.asm"
; void print_int_d(int {rdi}, int {rsi});

%include "lib/io/print_array_int.asm"
; void print_array_int(int {rdi}, int* {rsi}, int {rdx}, int {rcx}, int {r8}
;	void* {r9});

%include "lib/io/print_chars.asm"
; void print_chars(int {rdi}, char* {rsi}, int {rdx});

%include "lib/sys/exit.asm"	
; void exit(byte {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PRINT_CASES:
	mov rdi,SYS_STDOUT
	xor r15,r15
.loop:
	; print 'CASE '
	mov rsi,.grammar
	mov rdx,5
	call print_chars

	; print case number
	mov rsi,r15 
	call print_int_d

	; print ':'
	mov rsi,.grammar+5
	mov rdx,1
	call print_chars

	; determine if we know the value
	mov rsi,[STATUSES+8*r15]
	test rsi,rsi
	jnz .known_value
.unknown_value:
	; print '???'
	mov rsi,.grammar+6
	mov rdx,3
	call print_chars
	jmp .value_printed
.known_value:
	; print '$'
	mov rsi,.grammar+11
	mov rdx,1
	call print_chars
	; print value
	mov rsi,[STATUSES+8*r15]
	call print_int_d
.value_printed:
	test r15,1	; check if we are a multiple of 2
	jz .print_tab
.print_newline:	; print newline
	mov rsi,.grammar+10
	mov rdx,1
	call print_chars
	jmp .trailing_grammar_printed
.print_tab:	; print tab
	mov rsi,.grammar+9
	mov rdx,1
	call print_chars
.trailing_grammar_printed:
	; loop until done
	inc r15
	cmp r15,26
	jl .loop
	ret

.grammar:
	db `CASE :???\t\n$`

PRINT_INFO:
	; print instructions
	mov rdi,SYS_STDOUT
	mov rsi,.grammar1
	mov rdx,.grammar2-.grammar1
	call print_chars

	; print appraisal
	mov rsi,9999
	call print_int_d

	; print trailing newline
	mov rsi,.grammar1
	mov rdx,1
	call print_chars

	ret

.grammar1:
	db `\ntype a number 0-26 to open a case`
	db `\ntype 'w' to walk away with your case (& quit)`
	db `\ntype 's' to sell your case for: $`
.grammar2:

START:
	; random integer array for shuffling	
	mov rdi,SHUFFLE_ARRAY
	xor rsi,rsi
	mov rdx,26
	mov rcx,0
	mov r8,25
	call rand_int_array

	; fisher-yates shuffle the cases
	xor r15,r15
.shuffle_loop:
	mov rax,[SHUFFLE_ARRAY+8*r15]	; {rax} contains i'th random number
	mov rbx,[CASES+8*rax]	; {rbx} contains selected case number
	mov rcx,[CASES+8*r15]	; {rcx} contains the i'th case number
	mov [CASES+8*rax],rcx	; swap those 2 cases
	mov [CASES+8*r15],rbx
	inc r15
	cmp r15,26
	jl .shuffle_loop

	; game loop
.game_loop:

	mov qword [STATUSES+160],1000000

	call PRINT_CASES
	call PRINT_INFO
	call print_buffer_flush
	call exit
	
	; print the cases 
	mov rdi,SYS_STDOUT
	mov rsi,CASES
	mov rdx,26
	mov rcx,1
	xor r8,r8
	mov r9,print_int_d
	call print_array_int

	call print_buffer_flush

	xor dil,dil
	call exit	

SHUFFLE_ARRAY:
	times 26 dq 0

CASES:
	dq 0,1,2,3,4,5,6,7,8,9,10,11,12,13
	dq 14,15,16,17,18,19,20,21,22,23,24,25

STATUSES: ; 0 for unknown, otherwise contains the known value
	times 26 dq 0

VALUES:	; 26 case values, in dollars
	dq 0
	dq 1
	dq 5
	dq 10
	dq 25
	dq 50
	dq 75
	dq 100
	dq 200
	dq 300
	dq 400
	dq 500
	dq 750
	dq 1000
	dq 5000
	dq 10000
	dq 25000
	dq 50000
	dq 75000
	dq 100000
	dq 200000
	dq 300000
	dq 400000
	dq 500000
	dq 750000
	dq 1000000

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
