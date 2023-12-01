;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define LOAD_ADDRESS 0x00020000 ; pretty much any number >0 works
%define CODE_SIZE END-(LOAD_ADDRESS+0x78) ; everything beyond HEADER is code
%define PRINT_BUFFER_SIZE 4096
%define HEAP_SIZE 0x1000000 ; ~16 MB

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

%include "lib/io/framebuffer/framebuffer_init.asm"
; void framebuffer_init(void);

%include "lib/io/framebuffer/framebuffer_clear.asm"
; void framebuffer_clear(uint {rdi});

%include "lib/io/framebuffer/framebuffer_flush.asm"
; void framebuffer_flush(void);

%include "lib/io/bitmap/set_filled_rect.asm"
%include "lib/math/rand/rand_int.asm"

%include "lib/sys/exit.asm"	
; void exit(byte {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GREECE: ; draws flag of greece with top-left at ({r14},{r15})
	
	; blue background
	mov rsi,0x1000D5EAF
	mov r8d,r14d
	mov r9d,r15d
	mov r10d,r14d
	add r10d,600
	mov r11d,r15d
	add r11d,400
	call set_filled_rect

	; white stripes
	mov rsi,0x1FFFFFFFF
	add r9d,311
	sub r11d,45
	call set_filled_rect

	sub r9d,89
	sub r11d,89
	call set_filled_rect

	add r8d,222
	sub r9d,89
	sub r11d,89
	call set_filled_rect
	
	sub r9d,89
	sub r11d,89
	call set_filled_rect
	
	; white cross
	mov r8d,r14d
	mov r9d,r15d
	add r9d,89
	mov r10d,r14d
	mov r11d,r15d
	add r10d,221
	add r11d,132
	call set_filled_rect

	mov r8d,r14d
	add r8d,89
	mov r9d,r15d
	mov r10d,r14d
	add r10d,133
	mov r11d,r15d
	add r11d,221
	call set_filled_rect

	ret

ITALY:

	; stripe 1
	mov rsi,0x1FF008C45
	mov r8d,r14d
	mov r9d,r15d
	mov r10d,r14d
	add r10d,200
	mov r11d,r15d
	add r11d,400
	call set_filled_rect

	; stripe 2
	mov rsi,0x1FFF4F9FF
	add r8d,201
	add r10d,200
	call set_filled_rect

	; stripe 3
	mov rsi,0x1FFCD212A
	add r8d,200
	add r10d,200
	call set_filled_rect

	ret

FRANCE:

	; stripe 1
	mov rsi,0x1FF002654
	mov r8d,r14d
	mov r9d,r15d
	mov r10d,r14d
	add r10d,200
	mov r11d,r15d
	add r11d,400
	call set_filled_rect

	; stripe 2
	mov rsi,0x1FFFFFFFF
	add r8d,201
	add r10d,200
	call set_filled_rect

	; stripe 3
	mov rsi,0x1FFED2939
	add r8d,200
	add r10d,200
	call set_filled_rect

	ret

BELGIUM:

	; stripe 1
	mov rsi,0x1FF2D2926
	mov r8d,r14d
	mov r9d,r15d
	mov r10d,r14d
	add r10d,200
	mov r11d,r15d
	add r11d,400
	call set_filled_rect

	; stripe 2
	mov rsi,0x1FFFFCD00
	add r8d,201
	add r10d,200
	call set_filled_rect

	; stripe 3
	mov rsi,0x1FFC8102E
	add r8d,200
	add r10d,200
	call set_filled_rect

	ret

ROMANIA:

	; stripe 1
	mov rsi,0x1FF002B7F
	mov r8d,r14d
	mov r9d,r15d
	mov r10d,r14d
	add r10d,200
	mov r11d,r15d
	add r11d,400
	call set_filled_rect

	; stripe 2
	mov rsi,0x1FFFCD116
	add r8d,201
	add r10d,200
	call set_filled_rect

	; stripe 3
	mov rsi,0x1FFCE1126
	add r8d,200
	add r10d,200
	call set_filled_rect

	ret


IRELAND:

	; stripe 1
	mov rsi,0x1FF009A44
	mov r8d,r14d
	mov r9d,r15d
	mov r10d,r14d
	add r10d,200
	mov r11d,r15d
	add r11d,400
	call set_filled_rect

	; stripe 2
	mov rsi,0x1FFFFFFFF
	add r8d,201
	add r10d,200
	call set_filled_rect

	; stripe 3
	mov rsi,0x1FFFF8200
	add r8d,200
	add r10d,200
	call set_filled_rect

	ret

POLAND:

	; stripe 1
	mov rsi,0x1FFFFFFFF
	mov r8d,r14d
	mov r9d,r15d
	mov r10d,r14d
	add r10d,600
	mov r11d,r15d
	add r11d,200
	call set_filled_rect

	; stripe 2
	mov rsi,0x1FFDC143C
	add r9d,201
	add r11d,200
	call set_filled_rect

	ret


START:

	call heap_init
	call framebuffer_init

	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	
	; starting x
	xor rdi,rdi	
	mov esi,[framebuffer_init.framebuffer_width]
	sub esi,600
	call rand_int
	mov r14,rax

	; starting y
	mov esi,[framebuffer_init.framebuffer_height]
	sub esi,400
	call rand_int
	mov r15,rax

	; starting country
	mov rsi,[NUMBER_OF_COUNTRIES]
	dec rsi
	call rand_int
	shl rax,3
	add rax,COUNTRIES
	mov rbp,[rax]
	xor rbx,rbx
	
	mov r12,1	; dx
	mov r13,1	; dy
	xor rbx,rbx	; wall-collision flag

.loop:

	cmp r14d,0
	jne .not_left
	neg r12
	mov rbx,1
.not_left:
	mov eax,[framebuffer_init.framebuffer_width]
	sub eax,600
	cmp r14d,eax
	jne .not_right
	neg r12
	mov rbx,1
.not_right:
	cmp r15d,0
	jne .not_top
	neg r13
	mov rbx,1
.not_top:
	mov eax,[framebuffer_init.framebuffer_height]
	sub eax,400
	cmp r15d,eax
	jne .not_bottom
	neg r13
	mov rbx,1
.not_bottom:
	add r14d,r12d
	add r15d,r13d

	cmp rbx,1
	jne .flag_unchanged
	xor rdi,rdi
	mov rsi,[NUMBER_OF_COUNTRIES]
	dec rsi
	call rand_int
	shl rax,3
	add rax,COUNTRIES
	mov rbp,[rax]
	xor rbx,rbx
.flag_unchanged:

	xor rdi,rdi	
	call framebuffer_clear
	
	mov rdi,[framebuffer_init.framebuffer_address]
	call rbp

	call framebuffer_flush	; flush frame to framebuffer
	
	jmp .loop

NUMBER_OF_COUNTRIES:
	dq 7

COUNTRIES:
	dq GREECE
	dq ITALY
	dq POLAND
	dq FRANCE
	dq BELGIUM
	dq IRELAND
	dq ROMANIA

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)
