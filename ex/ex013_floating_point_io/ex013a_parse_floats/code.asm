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

%include "lib/io/parse_float.asm"
; double {xmm0} parse_float(char* {rdi});

%include "lib/io/print_chars.asm"
; void print_chars(int {rdi}, char* {rsi}, int {rdx});

%include "lib/io/print_float.asm"
; void print_float(int {rdi}, double {xmm0}, int {rsi});

%include "lib/sys/exit.asm"	
; void exit(byte {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

PRINT_NEWLINE:	; print a newline, violates ABI
	mov rsi,START.grammar
	mov rdx,1
	call print_chars
	ret

START:

	; parse and print float from string
	mov rdi,.float1
	call parse_float	; parse string to float into {xmm0}
	mov rdi,SYS_STDOUT
	mov rsi,8
	call print_float
	call PRINT_NEWLINE

	; parse and print float from string
	mov rdi,.float2
	call parse_float	; parse string to float into {xmm0}
	mov rdi,SYS_STDOUT
	mov rsi,8
	call print_float
	call PRINT_NEWLINE

	; parse and print float from string
	mov rdi,.float3
	call parse_float	; parse string to float into {xmm0}
	mov rdi,SYS_STDOUT
	mov rsi,8
	call print_float
	call PRINT_NEWLINE

	; parse and print float from string
	mov rdi,.float4
	call parse_float	; parse string to float into {xmm0}
	mov rdi,SYS_STDOUT
	mov rsi,8
	call print_float
	call PRINT_NEWLINE

	; parse and print float from string
	mov rdi,.float5
	call parse_float	; parse string to float into {xmm0}
	mov rdi,SYS_STDOUT
	mov rsi,8
	call print_float
	call PRINT_NEWLINE

	; parse and print float from string
	mov rdi,.float6
	call parse_float	; parse string to float into {xmm0}
	mov rdi,SYS_STDOUT
	mov rsi,8
	call print_float
	call PRINT_NEWLINE

	; parse and print float from string
	mov rdi,.float7
	call parse_float	; parse string to float into {xmm0}
	mov rdi,SYS_STDOUT
	mov rsi,8
	call print_float
	call PRINT_NEWLINE

	; parse and print float from string
	mov rdi,.float8
	call parse_float	; parse string to float into {xmm0}
	mov rdi,SYS_STDOUT
	mov rsi,8
	call print_float
	call PRINT_NEWLINE

	; parse and print float from string
	mov rdi,.float9
	call parse_float	; parse string to float into {xmm0}
	mov rdi,SYS_STDOUT
	mov rsi,8
	call print_float
	call PRINT_NEWLINE

	; parse and print float from string
	mov rdi,.float10
	call parse_float	; parse string to float into {xmm0}
	mov rdi,SYS_STDOUT
	mov rsi,8
	call print_float
	call PRINT_NEWLINE

	; flush print buffer
	call print_buffer_flush

	; exit
	xor dil,dil
	call exit	

.float1:
	db `123,`	; integer string
.float2:
	db `-123,`	; negative integer string
.float3:
	db `123.456,`	; decimal string
.float4:
	db `-123.456,`	; negative decimal string
.float5:
	db `123.456e6,`	; postive scientific notation decimal string
.float6:
	db `123.456e-6,`; negative scientific notation decimal string
.float7:
	db `-0.00000123e6,`; another example
.float8:
	db `+1230000.0e+6,`; another example
.float9:
	db `-123e3,`	; integer string with scientific notation
.float10:
	db `123e-3,`	; negative integer string with scientific notation

.grammar:
	db `\n`

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

