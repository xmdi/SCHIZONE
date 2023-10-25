;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define LOAD_ADDRESS 0x00020000 ; pretty much any number >0 works
%define CODE_SIZE END-(LOAD_ADDRESS+0x78) ; everything beyond HEADER is code
%define PRINT_BUFFER_SIZE 4096
%define HEAP_SIZE 128

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
	dq CODE_SIZE+PRINT_BUFFER_SIZE+HEAP_SIZE ; size (bytes) of segment in memory
	dq 0x0000000000000000 ; alignment (doesn't matter, only 1 segment)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INCLUDES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%include "syscalls.asm"	; requires syscall listing for your OS in lib/sys/	

%include "lib/mem/heap_init.asm"
; void heap_init(void);

%include "lib/mem/heap_free.asm"
; bool {rax} heap_free(void* {rdi});

%include "lib/mem/heap_alloc.asm"
; void* {rax} heap_alloc(long {rdi});

%include "lib/io/print_array_float.asm"	
; void print_array_float(int {rdi}, int* {rsi}, int {rdx}, int {rcx}, int {r8}
;	void* {r9}, int {r10});

%include "lib/math/expressions/trig/sine.asm"
; double {xmm0} sine(double {xmm0}, double {xmm1});

%include "lib/math/root_finding/bisection_method.asm"
; ulong {rax}, double {xmm0} bisection_method(void* {rdi}, double {xmm0}, 
;					double {xmm1}, double {xmm2});

%include "lib/sys/exit.asm"	
; void exit(byte {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; double {xmm0} FUNC(double {xmm0});
;	sine(x)
FUNC:
	sub rsp,16
	movdqu [rsp+0],xmm1
	movsd xmm1,[.tolerance]
	call sine
	movdqu xmm1,[rsp+0]
	add rsp,16
	ret

.tolerance:
	dq 0.0001

START:

	; algorithm:

	; start at lower bound, record sign
	; increment by step until we flip sign
	; count number of sign flips (N, number of roots) until upper bound
	; alloc an array of 8*N bytes
	; start again at lower bound, record sign
	; increment by step until we flip sign
	; use bisection method to identify root
	; add root to array
	; loop until at upper bound
	; return pointer to array and number of roots

	call heap_init

	mov rdi,FUNC
	xor rdx,rdx
	xor rcx,rcx
	movsd xmm3,[.lower_bound]
	
.count_roots_loop:
	
	xor rbx,rbx	; 0 for positive, 1 for negative

	movsd xmm0,xmm3
	call rdi

	comisd xmm0,[.zero]
	jae .sign_compare
	inc rbx	
.sign_compare:
	cmp rbx,rdx
	je .no_root_detected
	inc rcx
.no_root_detected:
	mov rdx,rbx
	addsd xmm3,[.step]
	comisd xmm3,[.upper_bound]
	jbe .count_roots_loop

	; {rcx} contains the number of roots in our range	
	
	mov rdi,rcx
	shl rdi,3
	call heap_alloc
	mov r8,rax

	; {r8} now contains the address of an array for the roots

	mov rdi,FUNC
	xor rdx,rdx
	movsd xmm3,[.lower_bound]
	
.find_roots_loop:
	
	xor rbx,rbx	; 0 for positive, 1 for negative

	movsd xmm0,xmm3
	call rdi

	comisd xmm0,[.zero]
	jae .sign_compare2
	inc rbx	
.sign_compare2:
	cmp rbx,rdx
	je .no_root_detected2
	movsd xmm0,xmm1
	movsd xmm1,xmm3
	movsd xmm2,[.tolerance]
	call bisection_method

	movsd [r8],xmm0
	add r8,8

.no_root_detected2:

	movsd xmm1,xmm3
	
	mov rdx,rbx
	addsd xmm3,[.step]
	comisd xmm3,[.upper_bound]
	jbe .find_roots_loop

	; print roots
	mov rdi,SYS_STDOUT	; STDOUT file descriptor
	mov rsi,r8		; matrix start address
	mov rdx,rcx		; 4 rows
	mov rcx,1		; 4 columns
	xor r8,r8		; no extra offsets betwixt elements
	mov r9,print_float	; print without scientific notation
	mov r10,5		; 5 significant figures
	call print_array_float

	; flush print buffer
	call print_buffer_flush

	; exit
	mov dil,cl
	call exit	

.lower_bound:
	dq -10.0
.upper_bound:
	dq 10.0
.step:
	dq 0.1
.zero:
	dq 0.0
.tolerance:
	dq 0.0001

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)
