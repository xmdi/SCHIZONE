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

;%include "lib/io/print_int_h.asm"
%include "lib/io/print_int_d.asm"
; void print_int_h(int {rdi}, int {rsi});

%include "lib/sys/exit.asm"	
; void exit(byte {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%if 1

align 64
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
	dec ebx
	jmp FRACTIONAL_BISECT
.shrink_up:
	inc eax
	jmp FRACTIONAL_BISECT
.done:
	ret
%endif

%if 0
align 64
FRACTIONAL_BISECT:
	cmp rcx,16777216 ; 2^-24 = 7 decimal places
	jg .done

	mov rdx,rax	; {rax} lower bound numerator
	add rdx,rbx	; {rbx} upper bound numerator
			; {rdx} midpoint numerator
	shl rax,1	
	shl rbx,1
	shl rcx,1	; {rcx} global denominator
	
	mov rsi,rcx	
	mov rdi,rdx
	imul rsi,rsi
	imul rdi,rdi
	shl rsi,1

	cmp rdi,rsi	; evaluate estimate
	jl .shrink_up
.shrink_down:
	mov rbx,rdx
	jmp FRACTIONAL_BISECT
align 16
.shrink_up:
	mov rax,rdx
	jmp FRACTIONAL_BISECT
align 16
.done:
	ret
%endif

%if 0
align 16
BISECT:
	movsd xmm5,xmm1
	subsd xmm5,xmm0
	comisd xmm5,xmm11
	jb .done

	inc rdi	; {rdi} counts iterations

	movsd xmm2,xmm0 ; {xmm0}=  lower bound
	addsd xmm2,xmm1 ; {xmm1} = upper bound
	mulsd xmm2,xmm13 ; {xmm2} = midpoint
	
	movsd xmm5,xmm0
	movsd xmm6,xmm2
	mulsd xmm5,xmm5	; x0*x0
	mulsd xmm6,xmm6	; xm*xm

	movsd xmm3,xmm6
	mulsd xmm3,xmm5	; xm*xm*x0*x0

	movsd xmm4,xmm6
	addsd xmm4,xmm5 ; xm*xm+x0*x0

	mulsd xmm4,xmm10

	comisd xmm3,xmm4
	jb .shrink_down
.shrink_up:
	movsd xmm0,xmm2
	jmp BISECT
align 16
.shrink_down:
	movsd xmm1,xmm2
	jmp BISECT
align 16
.done:
	ret	
%endif
%if 0
align 16
NEWTON:

	;inc rdi	

	; {xmm0} is x0
	movsd xmm1,xmm0
	mulsd xmm1,xmm1
	subsd xmm1,[TWO] ; {xmm1} = f(x0)
		
	movsd xmm2,xmm0
	mulsd xmm2,[TWO] ; {xmm2} = f'(x0)

	divsd xmm1,xmm2 ; {xmm1} = correction

	comisd xmm1,[TOLERANCE]
	jb .done

	subsd xmm0,xmm1
	jmp NEWTON

.done:

	ret
%endif	

align 64
START:

%if 0
	mov r15,100000000

movsd xmm14,[ONE]
movsd xmm15,[TWO]
movsd xmm13,[HALF]
movsd xmm12,[NEG_FOUR]
movsd xmm11,[TOLERANCE]
movsd xmm10,[EIGHT]
.loop_bisect:
	
	movsd xmm0,xmm14
	movsd xmm1,xmm15
	xor rdi,rdi
	call BISECT
	dec r15
	jnz .loop_bisect
;	call exit
	movq rsi,xmm0
	mov rdi,SYS_STDOUT
	call print_int_h
	call print_buffer_flush

%endif
%if 0
	mov r15,100000000

.loop_newton:
	
	movsd xmm0,[TWO]
	xor rdi,rdi
	call NEWTON
	dec r15
	jnz .loop_newton
%endif

%if 0
	mov r15,100000000
.loop:
	mov rax,1
	mov rbx,2
	mov rcx,1
	call FRACTIONAL_BISECT
	dec r15
	jnz .loop
	
	mov rdi,SYS_STDOUT
	mov rsi,rdx
	call print_int_d

	mov rsi,GRAMMAR
	mov rdx,1
	call print_chars

	mov rsi,rcx
	call print_int_d

	mov rsi,GRAMMAR+1
	mov rdx,1
	call print_chars

	call print_buffer_flush
%endif

%if 1
	mov r15,100000000
.loop:
	mov eax,1
	xor cl,cl
	mov ebx,2
	mov ebp,1
	mov esi,2
	call FRACTIONAL_BISECT
	dec r15
	jnz .loop
	
	mov rdi,SYS_STDOUT
	mov rsi,rax
	call print_int_d

	mov rsi,GRAMMAR
	mov rdx,1
	call print_chars

	mov rsi,rbp
	call print_int_d

	mov rsi,GRAMMAR+1
	mov rdx,1
	call print_chars

	call print_buffer_flush
%endif


	xor dil,dil
	call exit	

align 16
NEG_FOUR:
	dq -4.0

align 16
ZERO:
	dq 0.0

align 16
HALF:
	dq 0.5

align 16
ONE:
	dq 1.0

align 16
TWO:
	times 2 dq 2.0

align 16
EIGHT:
	dq 8.0

align 16
TOLERANCE:
	dq 0.0000001

GRAMMAR:
	db `/\n`

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros
