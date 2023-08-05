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

%include "lib/mem/memset.asm"
; void memset(void* {rdi}, char {sil}, ulong {rdx});

%include "lib/io/print_int_d.asm"
; void print_int_d(int {rdi}, int {rsi});

%include "lib/io/print_int_h.asm"
; void print_int_h(int {rdi}, int {rsi});

%include "lib/io/print_chars.asm"
; void print_chars(int {rdi}, char* {rsi}, int {rdx});

%include "lib/io/print_memory.asm"
; void print_memory(int {rdi}, byte* {rsi}, void* {rdx}, int {rcx});

%include "lib/sys/exit.asm"	
; void exit(byte {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

START:

	; initialize heap
	call heap_init


	; allocate 24-byte chunk of "0x1" bytes, save address in {r13}
	mov rdi,24
	call heap_alloc
	mov r13,rax
	; set chunk to all 1s
	mov rdi,r13
	mov rsi,1
	mov rdx,24
	call memset


	; allocate 24-byte chunk of "0x2" bytes, save address in {r14}
	mov rdi,24
	call heap_alloc
	mov r14,rax
	; set chunk to all 2s
	mov rdi,r14
	mov rsi,2
	mov rdx,24
	call memset


	; allocate 24-byte chunk of "0x3" bytes, save address in {r14}
	mov rdi,24
	call heap_alloc
	mov r15,rax
	; set chunk to all 3s
	mov rdi,r15
	mov rsi,3
	mov rdx,24
	call memset


	; print heap contents
	mov rdi,SYS_STDOUT
	mov rsi,HEAP_START_ADDRESS
	mov rdx,print_int_h
	mov rcx,HEAP_SIZE
	call print_memory

jmp .exit

	; free first and third chunk
	mov rdi,r13
	call heap_free
	mov rdi,r15
	call heap_free

	
	; print heap contents
	mov rdi,SYS_STDOUT
	mov rsi,HEAP_START_ADDRESS
	mov rdx,print_int_h
	mov rcx,HEAP_SIZE
	call print_memory
	call print_buffer_flush


	; allocate 16-byte chunk of "0x4" bytes, save address in {r13}
	mov rdi,16
	call heap_alloc
	mov r13,rax
	; set chunk to all 4s
	mov rdi,r13
	mov rsi,4
	mov rdx,16
	call memset

	; allocate 16-byte chunk of "0x5" bytes, save address in {r15}
	mov rdi,16
	mov r12,777	
	call heap_alloc
	mov r15,rax
	; set chunk to all 5s
	mov rdi,r15
	mov rsi,5
	mov rdx,16
	call memset

	; print heap contents
	mov rdi,SYS_STDOUT
	mov rsi,HEAP_START_ADDRESS
	mov rdx,print_int_h
	mov rcx,HEAP_SIZE
	call print_memory

.exit:
	; flush print buffer
	mov rdi,SYS_STDOUT
	call print_buffer_flush

	; exit
	xor dil,dil
	call exit	

.grammar0:
	db ` bytes successfully allocated at address: .\n`

.grammar1:
	db `Failed to allocate bytes.\n`

.grammar2:
	db ` bytes successfully freed from address: .\n`

.grammar3:
	db `Failed to free chunk at address: .\n`

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)
