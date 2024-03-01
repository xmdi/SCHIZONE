;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define LOAD_ADDRESS 0x00020000 ; pretty much any number >0 works
%define CODE_SIZE END-(LOAD_ADDRESS+0x78) ; everything beyond HEADER is code
%define PRINT_BUFFER_SIZE 4096
%define HEAP_SIZE 0x4000000

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

%include "lib/mem/memset.asm"
; void memset(void* {rdi}, char {sil}, ulong {rdx});

%include "lib/mem/heap_alloc.asm"
; void* {rax} heap_alloc(long {rdi});

%include "lib/mem/heap_free.asm"
; void heap_free(void* {rdi});

%include "lib/math/expressions/trig/sine.asm"
; double {xmm0} sine(double {xmm0}, double {xmm1});

%include "lib/math/expressions/trig/cosine.asm"
; double {xmm0} cosine(double {xmm0}, double {xmm1});

%include "lib/sys/exit.asm"
; void exit(char {dil});

%include "lib/io/framebuffer/framebuffer_3d_render_init.asm"

%include "lib/io/framebuffer/framebuffer_3d_render_loop.asm"

%include "lib/io/bitmap/set_line.asm"
; void set_line(void* {rdi}, int {esi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});

%include "lib/math/lin_alg/plu_solve.asm"
; void plu_solve(double* {rdi}, double* {rsi}, double* {rdx}, uint {rcx}, 
;						uint* {r8});

%include "lib/engr/fem/assemble_frame_elements.asm"
; void assemble_frame_elements(struct* {rdi});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; NOTE: NEED TO RUN THIS AS SUDO

DRAW_CROSS_CURSOR:
;	inputs:
; 	{rdi}=framebuffer_address
;	{rsi}=color
	mov rsi,0x1FFFFFF00
;	{edx}=framebuffer_width
;	{ecx}=framebuffer_height
;	{r8d}=mouse_x
;	{r9d}=mouse_y
	
	push r8
	push r9
	push r10
	push r11

	mov r10,r8
	sub r8,7
	add r10,7
	mov r11,r9
	call set_line
	
	mov r8,[rsp+24]
	mov r10,r8
	mov r11,r9
	add r9,14
	sub r11,7
	call set_line

	pop r11
	pop r10
	pop r9
	pop r8
	ret

START:
	
	call heap_init

	; generate stiffness matrix without boundary conditions
	mov rdi,.3D_FRAME
	call assemble_frame_elements

	; apply boundary conditions for node 0 (DOFs 0-5)
	movsd xmm0,[.zero]
	movsd xmm1,[.one]
	mov rdi,[.3D_FRAME+48]
	; first 6 columns of stiffness matrix to zero
	xor rcx,rcx
	mov r8,6
.bc_col_loop:
	mov r9,18
	mov rsi,rdi	
.bc_row_loop:
	movq [rsi],xmm0
	add rsi,144
	dec r9
	jnz .bc_row_loop
	add rdi,8	
	dec r8
	jnz .bc_col_loop

	mov rdi,[.3D_FRAME+48]
	xor sil,sil
	mov rdx,6*18*8	; first 6 rows of stiffness matrix to zero
	call memset
	movq [rdi],xmm1 ; diagonal 1.0 in the first 6 rows/columns
	movq [rdi+152],xmm1
	movq [rdi+304],xmm1
	movq [rdi+456],xmm1
	movq [rdi+608],xmm1
	movq [rdi+760],xmm1

	mov rdi,[.3D_FRAME+0]
	imul rdi,rdi,48
	call heap_alloc
	mov r8,rax	; pivoting vector

	; solve the linear system
	mov rdi,[.3D_FRAME+64]
	mov rsi,[.3D_FRAME+48]
	mov rdx,[.3D_FRAME+56]
	mov rcx,[.3D_FRAME+0]
	imul rcx,rcx,6
	; pivot vector space at {r8}
	call plu_solve

	mov rdi,r8
	call heap_free

	; populate the rendering items
	mov rbx,[.3D_FRAME+0]	
	mov [.undeformed_element_structure+0],rbx
	mov [.deformed_element_structure+0],rbx
	mov [.undeformed_node_structure+0],rbx
	mov [.deformed_node_structure+0],rbx
	mov rbx,[.3D_FRAME+8]	
	mov [.undeformed_element_structure+8],rbx
	mov [.deformed_element_structure+8],rbx
	mov rbx,[.3D_FRAME+24]	
	mov [.undeformed_element_structure+16],rbx
	mov [.undeformed_node_structure+8],rbx

	mov rdi,[.3D_FRAME+8]
	shl rdi,4
	call heap_alloc
	mov r8,rax ; r8 points to start of new edge list
	mov [.undeformed_element_structure+24],rax
	mov [.deformed_element_structure+24],rax

	mov r9,[.3D_FRAME+32] ; r9 points to start of element node list
	mov rcx,[.3D_FRAME+8] ; element counter

.element_population_loop:
	mov r10,[r9]
	mov [r8],r10
	mov r10,[r9+8]
	mov [r8+8],r10

	add r8,16
	add r9,24

	dec rcx
	jnz .element_population_loop
	
	; populate deformed node positions for render
	mov rdi,[.3D_FRAME+0]
	imul rdi,rdi,24
	call heap_alloc
	mov r8,rax ; r8 points to start of new node array
	mov [.deformed_element_structure+16],rax
	mov [.deformed_node_structure+8],rax
	mov rsi,[.3D_FRAME+24]
	mov rdx,[.3D_FRAME+64]

	mov rdi,[.3D_FRAME+0]
.deformed_node_position_loop:
	movq xmm0,[rsi+0]
	addsd xmm0,[rdx+0]
	movq [r8+0],xmm0
	movq xmm0,[rsi+8]
	addsd xmm0,[rdx+8]
	movq [r8+8],xmm0
	movq xmm0,[rsi+16]
	addsd xmm0,[rdx+16]
	movq [r8+16],xmm0
	add r8,24
	add rsi,24
	add rdx,48
	dec rdi
	jnz .deformed_node_position_loop	
	
	mov rdi,.perspective_structure
	mov rsi,.undeformed_element_geometry
	mov rdx,DRAW_CROSS_CURSOR
	call framebuffer_3d_render_init

.loop:
	call framebuffer_3d_render_loop
	jmp .loop

.3D_FRAME: ; 3D frame FE system
		dq 3 ; number of nodes (6 DOF per node)
		dq 2 ; number of elements
		dq 1 ; number of element types
		dq .node_array ; pointer to node coordinate array
			; each row: (double) x,y,z
		dq .element_array ; pointer to element array 
			; each row: (long) nodeID_A,nodeID_B,elementType
		dq .element_type_matrix ; pointer to element type matrix
			; each row (double) E,G,A,Iy,Iz,J,Vx,Vy,Vz
		dq .stiffness_matrix ; pointer to stiffness matrix (K)
		dq .forcing_matrix ; pointer to known forcing array (F)
		dq .unknown_matrix ; pointer to unknown DoF array (U)

.zero:
	dq 0.0
.one:
	dq 1.0
.node_array:
	dq 0.0,0.0,0.0 ; x, y, z
	dq 0.5,0.0,0.0
	dq 1.0,0.0,0.0
.element_array:
	dq 0,1,0  ; node A, node B, element type
	dq 1,2,0
.element_type_matrix:
	dq 1000000.0 ; E
	dq 100000.0 ; G
	dq 1.0 ; A
	dq 0.0833333 ; Iy
	dq 0.0833333 ; Iz
	dq 0.1666667 ; J
	dq 0.0 ; Vx
	dq 1.0 ; Vy
	dq 0.0 ; Vz
.stiffness_matrix:
	times 18*18 dq 0.0
.forcing_matrix:
	times 13 dq 0.0
	dq -50000.0
	times 4 dq 0.0
.unknown_matrix:
	times 18 dq 0.0

align 16

.perspective_structure:
	dq 0.50 ; lookFrom_x	
	dq 0.00 ; lookFrom_y	
	dq 5.00 ; lookFrom_z	
	dq 0.50 ; lookAt_x	
	dq 0.00 ; lookAt_y	
	dq 0.00 ; lookAt_z	
	dq 0.0 ; upDir_x	
	dq 1.0 ; upDir_y	
	dq 0.0 ; upDir_z	
	dq 0.7	; zoom

align 16

.undeformed_element_geometry:
	dq .undeformed_nodes_geometry ; next geometry in linked list
	dq .undeformed_element_structure ; address of point/edge/face structure
	dq 0x1FF00FF00 ; color (0xARGB)
	db 0b00000010 ; type of structure to render

align 16

.undeformed_nodes_geometry:
	dq .deformed_element_geometry ; next geometry in linked list
	dq .undeformed_node_structure ; address of point/edge/face structure
	dq 0x1FF00FF00 ; color (0xARGB)
	db 0b00000001 ; type of structure to render

align 16

.undeformed_element_structure:
	dq 0 ; number of points (N)
	dq 0 ; number of edges (M)
	dq 0 ; starting address of point array (3N elements)
	dq 0 ; starting address of edge array (2M elements)

align 16

.undeformed_node_structure:
	dq 0 ; number of points (N)
	dq 0 ; starting address of point array (3N elements)
	dq 1 ; point render type (1=O,2=X,3=[],4=tri)
	dq 15 ; characteristic size of each point

align 16

.deformed_element_geometry:
	dq .deformed_nodes_geometry ; next geometry in linked list
	dq .deformed_element_structure ; address of point/edge/face structure
	dq 0x1FFFF0000 ; color (0xARGB)
	db 0b00000010 ; type of structure to render

align 16

.deformed_nodes_geometry:
	dq 0 ; next geometry in linked list
	dq .deformed_node_structure ; address of point/edge/face structure
	dq 0x1FFFF0000 ; color (0xARGB)
	db 0b00000001 ; type of structure to render

align 16

.deformed_element_structure:
	dq 0 ; number of points (N)
	dq 0 ; number of edges (M)
	dq 0 ; starting address of point array (3N elements)
	dq 0 ; starting address of edge array (2M elements)

align 16

.deformed_node_structure:
	dq 0 ; number of points (N)
	dq 0 ; starting address of point array (3N elements)
	dq 2 ; point render type (1=O,2=X,3=[],4=tri)
	dq 15 ; characteristic size of each point


END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)

