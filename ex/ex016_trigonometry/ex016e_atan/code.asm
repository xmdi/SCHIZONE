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

%include "lib/time/tick_cycles.asm"
; uint {rax} tick_cycles(void);

%include "lib/time/tock_cycles.asm"
; uint {rax} tock_cycles(void);

%include "lib/math/expressions/trig/arctangent.asm"
; double {xmm0} arctangent(double {xmm0}, double {xmm1}, double {xmm2});

%include "lib/math/expressions/trig/arctangent_fast.asm"
; double {xmm0} arctangent_fast(double {xmm0}, double {xmm1}, double {xmm2});

%include "lib/io/print_chars.asm"
; void print_chars(int {rdi}, char* {rsi}, uint {rdx});

%include "lib/io/print_float.asm"
; void print_float(int {rdi}, double {xmm0}, int {rsi});

%include "lib/io/print_int_d.asm"
; void print_int_d(int {rdi}, int {rsi});

%include "lib/sys/exit.asm"	
; void exit(byte {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:
	mov rdi,SYS_STDOUT
	
	; time arctangent_fast
	
	mov r15,1000000
	call tick_cycles
.loop1:
	movsd xmm0,[.y_values]
	movsd xmm1,[.x_values]
	movsd xmm2,[.tolerance]
	call arctangent

	dec r15
	jnz .loop1
	
	call tock_cycles

	mov rsi,.grammar2
	mov rdx,8
	call print_chars

	mov rsi,.grammar2+13
	mov rdx,7
	call print_chars

	mov rsi,rax
	call print_int_d

	mov rsi,.grammar2+19
	mov rdx,8
	call print_chars

	; time arctangent_fast

	mov r15,1000000
	call tick_cycles
.loop2:
	movsd xmm0,[.y_values]
	movsd xmm1,[.x_values]
	call arctangent_fast

	dec r15
	jnz .loop2
	
	call tock_cycles

	mov rsi,.grammar2
	mov rdx,20
	call print_chars

	mov rsi,rax
	call print_int_d

	mov rsi,.grammar2+19
	mov rdx,9
	call print_chars

	; compare outputs
	mov r14,.y_values
	mov r15,.x_values
.loop3:
	; atan
	mov rsi,.grammar1
	mov rdx,4
	call print_chars

	mov rsi,.grammar1+9
	mov rdx,1
	call print_chars

	movsd xmm0,[r14]
	mov rsi,4
	call print_float

	mov rsi,.grammar1+10
	mov rdx,1
	call print_chars

	movsd xmm0,[r15]
	mov rsi,4
	call print_float

	mov rsi,.grammar1+11
	mov rdx,2
	call print_chars

	movsd xmm0,[r14]
	movsd xmm1,[r15]
	movsd xmm2,[.tolerance]
	call arctangent

	mov rsi,7
	call print_float
	
	mov rsi,.grammar1+13
	mov rdx,1
	call print_chars
	
	; atan_fast

	mov rsi,.grammar1
	mov rdx,10
	call print_chars

	movsd xmm0,[r14]
	mov rsi,4
	call print_float

	mov rsi,.grammar1+10
	mov rdx,1
	call print_chars

	movsd xmm0,[r15]
	mov rsi,4
	call print_float

	mov rsi,.grammar1+11
	mov rdx,2
	call print_chars

	movsd xmm0,[r14]
	movsd xmm1,[r15]
	call arctangent_fast

	mov rsi,7
	call print_float
	
	mov rsi,.grammar1+13
	mov rdx,2
	call print_chars

	add r14,8
	add r15,8

	cmp r14,.y_values+72
	jbe .loop3

	call print_buffer_flush

	; exit
	xor dil,dil
	call exit	


.x_values:
	dq 0.3
	dq 0.0
	dq 0.0
	dq 0.0
	dq 0.5
	dq -0.5
	dq 0.5
	dq -0.5
	dq -0.5
	dq 0.5

.y_values:
	dq 0.1
	dq 0.0
	dq 0.5
	dq -0.5
	dq 0.0
	dq 0.0
	dq 0.5
	dq 0.5
	dq -0.5
	dq -0.5

.tolerance:
	dq 0.00001

.grammar1:
	db `atan_fast(,)=\n\n`

.grammar2:
	db `1e6 atan_fast()s in cycles\n\n`

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
