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

%include "lib/math/vector/normalize_3.asm"
; void normalize_3(double* {rdi});

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
	mov rdi,.view_axes_old+0
	mov rsi,.perspective_structure+48
	mov rdx,.perspective_structure+0
	call cross_product_3	

	mov rdi,.view_axes_old+24
	mov rsi,.perspective_structure+48
	mov rdx,24
	call memcopy

	movsd xmm15,[.perspective_structure+0]
	subsd xmm15,[.perspective_structure+24]
	movsd [.view_axes_old+48],xmm15
	movsd xmm15,[.perspective_structure+8]
	subsd xmm15,[.perspective_structure+32]
	movsd [.view_axes_old+56],xmm15
	movsd xmm15,[.perspective_structure+16]
	subsd xmm15,[.perspective_structure+40]
	movsd [.view_axes_old+64],xmm15

	; normalize the axes
	mov rdi,.view_axes_old+0
	call normalize_3
	mov rdi,.view_axes_old+24
	call normalize_3
	mov rdi,.view_axes_old+48
	call normalize_3

	; copy up-direction into structure
	mov rdi,.perspective_structure+48
	mov rsi,.view_axes_old+24
	mov rdx,24
	call memcopy

	; copy looking direction into structure
	movsd xmm15,[.view_axes_old+48]
	addsd xmm15,[.perspective_structure+24]
	movsd [.perspective_structure+0],xmm15
	movsd xmm15,[.view_axes_old+56]
	addsd xmm15,[.perspective_structure+32]
	movsd [.perspective_structure+8],xmm15
	movsd xmm15,[.view_axes_old+64]
	addsd xmm15,[.perspective_structure+40]
	movsd [.perspective_structure+16],xmm15

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

	xor r14,r14	; flag to track if we have been holding left click

.loop:
	; check mouse status	
	call framebuffer_mouse_poll

	xor rax,rax
	; if left click isn't pressed, nothing to draw but cursor
	cmp byte [framebuffer_mouse_init.mouse_state],0
	cmove r12,rax
	cmove r13,rax
	je .no_drawing

	; if we just clicked for the first time, just save the current 
	;    mouse position and don't draw anything new

	mov r14,1
	
	mov rax,r12
	add rax,r13
	cmp rax,0
	je .first_click

	; clear the background first
	mov rdi,r15
	xor sil,sil
	mov rdx,[framebuffer_init.framebuffer_size]
	call memset

	movsxd r8,[framebuffer_mouse_init.mouse_x]
	movsxd r9,[framebuffer_mouse_init.mouse_y]

	cmp byte [framebuffer_mouse_init.mouse_state],1
	je .left_click
	cmp byte [framebuffer_mouse_init.mouse_state],2
	je .right_click
	cmp byte [framebuffer_mouse_init.mouse_state],4
	je .middle_click
	
.left_click:
	; (rotating)
	; rotate the look_From point about the look_At point

	mov rax,r8
	sub rax,r12
	cvtsi2sd xmm0,rax
	mulsd xmm0,[.rotate_scale]
	movsd [.yaw],xmm0	
	
	mov rax,r9
	sub rax,r13
	cvtsi2sd xmm0,rax
	mulsd xmm0,[.rotate_scale]
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

	; grab the old view system
	mov rdi,.view_axes
	mov rsi,.view_axes_old
	mov rdx,72
	call memcopy

	;.u1'[0]
	movsd xmm15,[.view_axes+8]
	mulsd xmm15,[.view_axes+40]
	movsd xmm14,[.view_axes+16]
	mulsd xmm14,[.view_axes+32]
	subsd xmm15,xmm14
	mulsd xmm15,[.sin_yaw]
	movsd xmm0,[.view_axes+0]
	mulsd xmm0,[.cos_yaw]
	addsd xmm0,xmm15

	;.u1'[1]
	movsd xmm15,[.view_axes+16]
	mulsd xmm15,[.view_axes+24]
	movsd xmm14,[.view_axes+0]
	mulsd xmm14,[.view_axes+40]
	subsd xmm15,xmm14
	mulsd xmm15,[.sin_yaw]
	movsd xmm1,[.view_axes+8]
	mulsd xmm1,[.cos_yaw]
	addsd xmm1,xmm15

	;.u1'[2]
	movsd xmm15,[.view_axes+0]
	mulsd xmm15,[.view_axes+32]
	movsd xmm14,[.view_axes+8]
	mulsd xmm14,[.view_axes+24]
	subsd xmm15,xmm14
	mulsd xmm15,[.sin_yaw]
	movsd xmm2,[.view_axes+16]
	mulsd xmm2,[.cos_yaw]
	addsd xmm2,xmm15

	; move rotated .u1' into the view_axes
	movsd [.view_axes+0],xmm0
	movsd [.view_axes+8],xmm1
	movsd [.view_axes+16],xmm2

	;.u2'[0]
	movsd xmm15,[.view_axes+32]
	mulsd xmm15,[.view_axes+16]
	movsd xmm14,[.view_axes+40]
	mulsd xmm14,[.view_axes+8]
	subsd xmm15,xmm14
	mulsd xmm15,[.sin_pitch]
	movsd xmm0,[.view_axes+24]
	mulsd xmm0,[.cos_pitch]
	addsd xmm0,xmm15

	;.u2'[1]
	movsd xmm15,[.view_axes+40]
	mulsd xmm15,[.view_axes+0]
	movsd xmm14,[.view_axes+24]
	mulsd xmm14,[.view_axes+16]
	subsd xmm15,xmm14
	mulsd xmm15,[.sin_pitch]
	movsd xmm1,[.view_axes+32]
	mulsd xmm1,[.cos_pitch]
	addsd xmm1,xmm15

	;.u2'[2]
	movsd xmm15,[.view_axes+24]
	mulsd xmm15,[.view_axes+8]
	movsd xmm14,[.view_axes+32]
	mulsd xmm14,[.view_axes+0]
	subsd xmm15,xmm14
	mulsd xmm15,[.sin_pitch]
	movsd xmm2,[.view_axes+40]
	mulsd xmm2,[.cos_pitch]
	addsd xmm2,xmm15

	; move rotated .u2' into the view_axes
	movsd [.view_axes+24],xmm0
	movsd [.view_axes+32],xmm1
	movsd [.view_axes+40],xmm2

	;.u3'[0]
	movsd xmm15,[.view_axes+8]
	mulsd xmm15,[.view_axes+40]
	movsd xmm14,[.view_axes+16]
	mulsd xmm14,[.view_axes+32]
	subsd xmm15,xmm14
	movsd [.view_axes+48],xmm15

	;.u3'[1]
	movsd xmm15,[.view_axes+16]
	mulsd xmm15,[.view_axes+24]
	movsd xmm14,[.view_axes+0]
	mulsd xmm14,[.view_axes+40]
	subsd xmm15,xmm14
	movsd [.view_axes+56],xmm15

	;.u3'[2]
	movsd xmm15,[.view_axes+0]
	mulsd xmm15,[.view_axes+32]
	movsd xmm14,[.view_axes+8]
	mulsd xmm14,[.view_axes+24]
	subsd xmm15,xmm14
	movsd [.view_axes+64],xmm15

	; copy up-direction into structure
	mov rdi,.perspective_structure+48
	mov rsi,.view_axes+24
	mov rdx,24
	call memcopy

	; copy looking direction into structure
	movsd xmm15,[.view_axes+48]
	addsd xmm15,[.perspective_structure+24]
	movsd [.perspective_structure+0],xmm15
	movsd xmm15,[.view_axes+56]
	addsd xmm15,[.perspective_structure+32]
	movsd [.perspective_structure+8],xmm15
	movsd xmm15,[.view_axes+64]
	addsd xmm15,[.perspective_structure+40]
	movsd [.perspective_structure+16],xmm15

	jmp .draw_cube

.right_click:
	; (panning)
	; translate both the lookat and lookfrom point along u1 and u2

	mov rax,r8
	sub rax,r12
	cvtsi2sd xmm0,rax
	mulsd xmm0,[.pan_scale_x]
	movsd xmm7,xmm0	; rightward shifting
	
	mov rax,r9
	sub rax,r13
	cvtsi2sd xmm0,rax
	mulsd xmm0,[.pan_scale_y]
	movsd xmm8,xmm0 ; upward shifting
	
	; adjust vector x-coords
	movsd xmm0,[.view_axes_old+0]
	mulsd xmm0,xmm7
	movsd xmm1,[.view_axes_old+24]
	mulsd xmm1,xmm8
	subsd xmm0,xmm1
	movsd xmm1,[.perspective_old+0]
	subsd xmm1,xmm0
	movsd [.perspective_structure+0],xmm1	
	movsd xmm1,[.perspective_old+24]
	subsd xmm1,xmm0
	movsd [.perspective_structure+24],xmm1	
	
	; adjust vector y-coords
	movsd xmm0,[.view_axes_old+8]
	mulsd xmm0,xmm7
	movsd xmm1,[.view_axes_old+32]
	mulsd xmm1,xmm8
	subsd xmm0,xmm1
	movsd xmm1,[.perspective_old+8]
	subsd xmm1,xmm0
	movsd [.perspective_structure+8],xmm1	
	movsd xmm1,[.perspective_old+32]
	subsd xmm1,xmm0
	movsd [.perspective_structure+32],xmm1	

	; adjust vector z-coords
	movsd xmm0,[.view_axes_old+16]
	mulsd xmm0,xmm7
	movsd xmm1,[.view_axes_old+40]
	mulsd xmm1,xmm8
	subsd xmm0,xmm1
	movsd xmm1,[.perspective_old+16]
	subsd xmm1,xmm0
	movsd [.perspective_structure+16],xmm1	
	movsd xmm1,[.perspective_old+40]
	subsd xmm1,xmm0
	movsd [.perspective_structure+40],xmm1	

	jmp .draw_cube

.middle_click:
	; (zooming)
	; adjust the zoom factor
	mov rax,r9
	sub rax,r13
	cvtsi2sd xmm0,rax
	mulsd xmm0,[.zoom_scale] ; zooming
	movsd xmm1,[.zoom_old]
	subsd xmm1,xmm0
	movsd [.perspective_structure+72],xmm1	

.draw_cube:
	; project & rasterize the cube onto the framebuffer
	mov rdi,r15
	mov rsi,0x1FFFFA500
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	mov r8,.perspective_structure
	mov r9,.edge_structure
	call rasterize_edges	

	jmp .was_not_dragging

.first_click:
	mov rdi,.view_axes
	mov rsi,.view_axes_old
	mov rdx,72
	call memcopy

	mov rdi,.perspective_old
	mov rsi,.perspective_structure
	mov rdx,48
	call memcopy

	mov rdi,.zoom_old
	mov rsi,.perspective_structure+72
	mov rdx,8
	call memcopy

	movsxd r12,[framebuffer_mouse_init.mouse_x]
	movsxd r13,[framebuffer_mouse_init.mouse_y]

.no_drawing:

	cmp r14,1
	jne .was_not_dragging
.just_finished_dragging:
	mov rdi,.view_axes_old
	mov rsi,.view_axes
	mov rdx,72
	call memcopy
	xor r14,r14	

.was_not_dragging:
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
.tolerance:
	dq 0.0001
.rotate_scale:
	dq 0.005
.pan_scale_x:
	dq 0.013
.pan_scale_y:
	dq 0.0062
.zoom_scale:
	dq 0.001


.view_axes:
.u1:
	times 3 dq 0.0
.u2:
	times 3 dq 0.0
.u3:	
	times 3 dq 0.0

.view_axes_old:
	times 3 dq 0.0
	times 3 dq 0.0
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

.perspective_old:
	times 6 dq 0.0
.zoom_old:
	dq 0.0

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

