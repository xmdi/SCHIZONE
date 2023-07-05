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

%include "lib/io/print_chars.asm"
; void print_chars(int {rdi}, char* {rsi}, int {rdx});

%include "lib/io/print_int_h.asm"
%include "lib/io/print_int_d.asm"
; void print_int_h(int {rdi}, int {rsi});

%include "lib/sys/exit.asm"	
; void exit(byte {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%if 0
align 16
FLOATING_POINT_BISECT:
	
	movsd xmm3,xmm1
	subsd xmm3,xmm0
	comisd xmm3,[TOLERANCE]
	jbe .ret

	movsd xmm2,xmm1
	addsd xmm2,xmm0
	divsd xmm2,[TWO]
	
	movsd xmm3,xmm2
	mulsd xmm3,xmm3

	comisd xmm3,[TWO]
	jbe .shrink_up
.shrink_down:
	movsd xmm1,xmm2
	jmp FLOATING_POINT_BISECT
align 16
.shrink_up:
	movsd xmm0,xmm2
	jmp FLOATING_POINT_BISECT
align 16
.ret:
	movsd xmm0,xmm2
	ret
%endif
%if 0
align 16
FIXED_POINT_BISECT:
	
	mov rcx,rsi
	sub rcx,rdi
	;cmp rcx,1
	cmp rcx,[TOLERANCE_FIXED]
	jbe .ret

	mov rdx,rsi
	add rdx,rdi
	shr rdx,1	; one difference

	mov rcx,rdx
	imul rcx,rcx	
	shr rcx,24

	cmp rcx,[TWO_FIXED]
	jbe .shrink_up
.shrink_down:
	mov rsi,rdx
	jmp FIXED_POINT_BISECT
align 16
.shrink_up:
	mov rdi,rdx
	jmp FIXED_POINT_BISECT
align 16
.ret:
	mov rax,rdx
	ret
%endif
%if 1
align 16
FRACTIONAL_BISECT:
;	cmp ebp,16777216 ; 2^-24 = 7 decimal places
	cmp cl,24
	jg .done
	shl eax,1		; {eax} lower bound numerator
	shl ebx,1		; {ebx} upper bound numerator
	mov edx,eax		
	inc cl
	inc edx			; {edx} midpoint numerator
	shl ebp,1		; {ebp} global denominator
	shl esi,2		; {esi} double squared denominator
	imul edx,edx		; {edi} midpoint numerator squared
	cmp edx,esi		; evaluate guess
	jl .shrink_up
.shrink_down:
	dec ebx
	jmp FRACTIONAL_BISECT
align 16
.shrink_up:
	inc eax
	jmp FRACTIONAL_BISECT
align 16
.done:
	ret
%endif

START:

	mov r15,100000000
%if 0
align 16
.loop_floating_point:
	movsd xmm0,[ONE]
	movsd xmm1,[TWO]

	call FLOATING_POINT_BISECT

	dec r15
	jnz .loop_floating_point

	mov rdi,SYS_STDOUT
	movq rsi,xmm0
	call print_int_h

	call print_buffer_flush

	call exit	

%endif
%if 0
align 16
.loop_fixed_point:
	mov rdi,[ONE_FIXED]
	mov rsi,[TWO_FIXED]

	call FIXED_POINT_BISECT

	dec r15
	jnz .loop_fixed_point

	mov rdi,SYS_STDOUT
	mov rsi,rax
	call print_int_h

	call print_buffer_flush

	call exit	

%endif

%if 1
align 16
.loop_fractional:
	mov eax,1
	xor cl,cl
	mov ebx,2
	mov ebp,1
	mov esi,2
	call FRACTIONAL_BISECT

	dec r15
	jnz .loop_fractional

	mov rdi,SYS_STDOUT
	mov rsi,rax
	call print_int_d

	mov rsi,GRAMMAR
	mov rdx,1
	call print_chars

	mov rsi,rbp; rcx
	call print_int_d

	mov rsi,GRAMMAR+1
	mov rdx,1
	call print_chars

	call print_buffer_flush


	mov rdi,FRACTIONAL_BISECT
	call exit	

%endif


ONE:
	dq 1.0
TWO:
	dq 2.0
TOLERANCE:
	dq 0.0000001

ONE_FIXED:
	dq 16777216 ; 1<<24
TWO_FIXED:
	dq 33554432 ; 1<<25
TOLERANCE_FIXED:
	dq 1 ; 1


GRAMMAR:
	db `/\n`

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
