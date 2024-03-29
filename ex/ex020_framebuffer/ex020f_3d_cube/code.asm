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

%include "lib/io/bitmap/rasterize_edges.asm"
; void rasterize_edges(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 struct* {r8}, struct* {r9});

%include "lib/math/vector/perpendicularize_3.asm"
; void perpendicularize_3(double* {rdi}, double* {rsi});

%include "lib/math/expressions/trig/sine.asm"
; double {xmm0} sine(double {xmm0}, double {xmm1});

%include "lib/math/expressions/trig/cosine.asm"
; double {xmm0} cosine(double {xmm0}, double {xmm1});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


START:

	call heap_init
	call framebuffer_init

.loop:

	; clear screen to black
	xor rdi,rdi	
	call framebuffer_clear

	; rotate the look_From point about the origin and global Z
	movsd xmm0,[.rotation_angle]
	movsd xmm1,[.tolerance]
	call cosine
	movsd [.perspective_structure+0],xmm0

	movsd xmm0,[.rotation_angle]
	movsd xmm1,[.tolerance]
	call sine
	movsd [.perspective_structure+8],xmm0

	; perpendicularize the Up-direction vector
	mov rdi,.perspective_structure+48
	mov rsi,.perspective_structure+0
	call perpendicularize_3

	; project & rasterize the cube onto the framebuffer
	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,0x1FFFFA500
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	mov r8,.perspective_structure
	mov r9,.edge_structure
	call rasterize_edges	

	; orbit
	movsd xmm0,[.rotation_angle]
	movsd xmm1,[.angle_increment]
	addsd xmm0,xmm1
	movsd [.rotation_angle],xmm0

	call framebuffer_flush	; flush frame to framebuffer

	jmp .loop

.rotation_angle:
	dq 0.0
.angle_increment:
	dq 0.005
.tolerance:
	dq 0.00001

.perspective_structure:
	dq 1.00 ; lookFrom_x	
	dq 0.00 ; lookFrom_y	
	dq 1.00 ; lookFrom_z	
	dq 0.00 ; lookAt_x	
	dq 0.00 ; lookAt_y	
	dq 0.00 ; lookAt_z	
	dq 1.0 ; upDir_x	
	dq 1.0 ; upDir_y	
	dq -1.0 ; upDir_z	
	dq 0.3	; zoom

.edge_structure:
	dq 8 ; number of points (N)
	dq 12 ; number of edges (M)
	dq .points ; starting address of point array (3N elements)
	dq .edges ; starting address of edge array (2M elements)

.points:
	dq -1.00,-1.00,-1.00
	dq -1.00,-1.00,1.00
	dq -1.00,1.00,-1.00
	dq -1.00,1.00,1.00
	dq 1.00,-1.00,-1.00
	dq 1.00,-1.00,1.00
	dq 1.00,1.00,-1.00
	dq 1.00,1.00,1.00

.edges:
	dq 0,1	
	dq 2,3	
	dq 4,5	
	dq 6,7	
	dq 0,2	
	dq 1,3
	dq 4,6
	dq 5,7
	dq 0,4	
	dq 1,5	
	dq 2,6
	dq 3,7	

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)
