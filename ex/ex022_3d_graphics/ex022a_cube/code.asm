;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define LOAD_ADDRESS 0x00020000 ; pretty much any number >0 works
%define CODE_SIZE END-(LOAD_ADDRESS+0x78) ; everything beyond HEADER is code
%define PRINT_BUFFER_SIZE 4096
%define HEAP_SIZE 0x2000000 ; ~32 MB

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

%include "lib/io/file_open.asm"
; int {rax} file_open(char* {rdi}, int {rsi}, int {rdx});

%include "lib/mem/memset.asm"
; void memset(void* {rdi}, char {sil}, ulong {rdx});

%include "lib/mem/memcopy.asm"
; void memcopy(long* {rdi}, long* {rsi}, ulong {rdx});

%include "lib/mem/heap_init.asm"
; void heap_init(void);

%include "lib/io/framebuffer/framebuffer_init.asm"
; void framebuffer_init(void);

%include "lib/io/framebuffer/framebuffer_mouse_init.asm"
; void framebuffer_mouse_init(void);

%include "lib/io/framebuffer/framebuffer_mouse_poll.asm"
; void framebuffer_mouse_poll(void);

%include "lib/io/bitmap/set_foreground.asm"
; void set_foreground(void* {rdi}, void* {rsi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});

%include "lib/io/framebuffer/framebuffer_clear.asm"
; void framebuffer_clear(uint {rdi});

%include "lib/io/framebuffer/framebuffer_flush.asm"
; void framebuffer_flush(void);

%include "lib/io/bitmap/set_pixel.asm"
; void set_pixel(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d});

%include "lib/io/bitmap/set_line.asm"
; void set_line(void* {rdi}, int {esi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});

%include "lib/io/bitmap/rasterize_edges.asm"
; void rasterize_edges(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 struct* {r8}, struct* {r9});

%include "lib/math/vector/perpendicularize_3.asm"
; void perpendicularize_3(double* {rdi}, double* {rsi});

%include "lib/math/expressions/trig/sine.asm"
; double {xmm0} sine(double {xmm0}, double {xmm1});

%include "lib/math/expressions/trig/cosine.asm"
; double {xmm0} cosine(double {xmm0}, double {xmm1});

%include "lib/math/matrix/matrix_multiply.asm"
; void matrix_multiply(double* {rdi}, double* {rsi}, double* {rdx}, uint {rcx}
;	uint {r8}, uint {r9});

%include "lib/math/vector/cross_product_3.asm"
; void cross_product_3(double* {rdi}, double* {rsi}, double* {rdx});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; NOTE: NEED TO RUN THIS AS SUDO

START:

	call heap_init

	call framebuffer_init
	
	call framebuffer_mouse_init

	mov rdi,[framebuffer_init.framebuffer_size]
	call heap_alloc
	mov r15,rax	; buffer to combine multiple layers

	; clear the screen to start
	mov rdi,0xFF000000
	call framebuffer_clear

	; perpendicularize the Up-direction vector
	mov rdi,.perspective_structure+48
	mov rsi,.perspective_structure+0
	call perpendicularize_3

	; compute rightward direction
	mov rdi,.right_dir
	mov rsi,.perspective_structure+48	; NOTE maybe these 2 are switched
	mov rdx,.perspective_structure+0
	call cross_product_3	

	; project & rasterize the cube onto the framebuffer
	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,0x1FFFFA500
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	mov r8,.perspective_structure
	mov r9,.edge_structure
	call rasterize_edges	
	
	call framebuffer_flush
	
	; copy this to the intermediate buffer to start
	mov rdi,r15
	mov rsi,[framebuffer_init.framebuffer_address]
	mov rdx,[framebuffer_init.framebuffer_size]
	call memcopy
	
	; these track the previous cursor location (while holding left mouse)
	xor r12,r12 ; x
	xor r13,r13 ; y

.loop:
	; check mouse status	
	call framebuffer_mouse_poll

	xor rax,rax
	; if left click isn't pressed, nothing to draw but cursor
	cmp byte [framebuffer_mouse_init.mouse_state],1
	cmovne r12,rax
	cmovne r13,rax
	jne .no_drawing

;;; draw cube
	; if we just clicked for the first time, just save the current 
	;    mouse position and don't draw anything new
	mov rax,r12
	add rax,r13
	cmp rax,0
	je .first_click

	; clear the background first
	mov rdi,r15
	xor sil,sil
	mov rdx,[framebuffer_init.framebuffer_size]
	call memset

	mov r8d,[framebuffer_mouse_init.mouse_x]
	mov r9d,[framebuffer_mouse_init.mouse_y]

	; rotate the look_From point about the origin and global Z

	mov eax,r8d
	sub eax,r12d
	cvtsi2sd xmm0,rax
	mulsd xmm0,[.scale]
	movsd [.yaw],xmm0	
	
	mov eax,r9d
	sub eax,r13d
	cvtsi2sd xmm0,rax
	mulsd xmm0,[.scale]
	movsd [.pitch],xmm0
	
	movsd xmm1,[.tolerance]
	call cosine
	movsd [.cos_pitch],xmm0

	movsd xmm0,[.pitch]
	call sine
	movsd [.sin_pitch],xmm0

	movsd xmm0,[.yaw]
	call cosine
	movsd [.cos_yaw],xmm0

	movsd xmm0,[.yaw]
	call sine
	movsd [.sin_yaw],xmm0

	mov xmm0





	; project & rasterize the cube onto the framebuffer
	mov rdi,r15
	mov rsi,0x1FFFFA500
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	mov r8,.perspective_structure
	mov r9,.edge_structure
	call rasterize_edges	

	jmp .no_drawing

.first_click:
	mov rdi,.lookFrom
	mov rsi,.perspective_structure
	mov rdx,24
	call memcopy

	mov r12d,[framebuffer_mouse_init.mouse_x]
	mov r13d,[framebuffer_mouse_init.mouse_y]

.no_drawing:
	
;;; combine layers to plot the cursor to the screen
	
	; first copy intermediate buffer to framebuffer
	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,r15
	mov rdx,[framebuffer_init.framebuffer_size]
	call memcopy

	; then copy the cursor as foreground onto the framebuffer
	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,PEPE_BIG
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	mov r8d,26
	mov r9d,14
	mov r10d,[framebuffer_mouse_init.mouse_x]
	mov r11d,[framebuffer_mouse_init.mouse_y]
	call set_foreground

	; flush output to the screen
	call framebuffer_flush

	jmp .loop

.yaw:
	dq 0.0
.pitch:
	dq 0.0
.sin_yaw:
	dq 0.0
.sin_pitch:
	dq 0.0
.cos_yaw:
	dq 0.0
.cos_pitch:
	dq 0.0
.neg_one:
	dq -1.0
.tolerance:
	dq 0.0001
.scale:
	dq 0.005
.rotation_matrix:
	times 9 dq 0.0

view_axes:
.u1:
	times 3 dq 0.0
.u2:
	times 3 dq 0.0
.u3:	
	times 3 dq 0.0


.lookFrom:
	dq 1.0
	dq 1.0
	dq 0.0
.right_dir:
	times 3 dq 0.0

.perspective_structure:
	dq 1.00 ; lookFrom_x	
	dq 1.00 ; lookFrom_y	
	dq 0.00 ; lookFrom_z	
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

%define G 0xFF2B7544
%define W 0xFFFFFFFF
%define B 0xFF000000
%define T 0x00000000
%define S 0xFF2945E3
%define R 0xFF780016

PEPE_BIG: ; (26x14)
	dd 0,0,0,0,0,0,G,G,G,G,0,0,G,G,G,G,0,0,0,0,0,0,0,0,0,0
	dd 0,0,0,0,0,0,G,G,G,G,0,0,G,G,G,G,0,0,0,0,0,0,0,0,0,0
	dd 0,0,0,0,G,G,G,G,G,G,G,G,G,G,G,G,G,G,0,0,0,0,0,0,0,0
	dd 0,0,0,0,G,G,G,G,G,G,G,G,G,G,G,G,G,G,0,0,0,0,0,0,0,0
	dd G,G,0,0,G,G,B,B,W,W,W,W,B,B,W,W,G,G,G,G,0,0,0,0,0,0
	dd G,G,0,0,G,G,B,B,W,W,W,W,B,B,W,W,G,G,G,G,0,0,0,0,0,0
	dd 0,0,G,G,0,0,G,G,G,G,G,G,G,G,G,G,G,G,G,G,0,0,0,0,G,G
	dd 0,0,G,G,0,0,G,G,G,G,G,G,G,G,G,G,G,G,G,G,0,0,0,0,G,G
	dd 0,0,0,0,G,G,R,R,R,R,R,R,R,R,G,G,G,G,G,G,G,G,0,0,G,G
	dd 0,0,0,0,G,G,R,R,R,R,R,R,R,R,G,G,G,G,G,G,G,G,0,0,G,G
	dd 0,0,0,0,0,0,S,S,G,G,G,G,G,G,G,G,G,G,G,G,G,G,0,0,G,G
	dd 0,0,0,0,0,0,S,S,G,G,G,G,G,G,G,G,G,G,G,G,G,G,0,0,G,G
	dd 0,0,0,0,0,0,0,0,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,0,0
	dd 0,0,0,0,0,0,0,0,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,0,0

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)

