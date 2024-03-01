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

%include "lib/mem/heap_free.asm"
; void heap_free(void* {rdi});

%include "lib/mem/memset.asm"
; void memset(void* {rdi}, char {sil}, ulong {rdx});

%include "lib/mem/heap_alloc.asm"
; void* {rax} heap_alloc(long {rdi});

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

GENERATE_LADDER_SYSTEM:
	; returns a pointer to 3D frame FEA structure in {rax} for a ladder with
	;	a 200-lb person standing on the top rung (top rung will always
	;	have an even number of elements >= {rsi}).

	; {rdi} = # rungs
	; {rsi} = # elements/rung ; TODO: currently only supports 2
	; {rdx} = # side rail elements between rungs
	; {rcx} = (double) length of rungs
	; {r8}  = (double) length of each side rails
	; {r9}  = (double) rung diameter
	; {r10} = (double) side rail cross-sectional width
	; {r11} = (double) side rail cross-sectional height
	; {r12} = {double} elastic modulus E
	; {r13} = {double} shear modulus G
	; {r14} = {double} ladder angle against wall (degrees)

	; 3D frame FEA system has this form:
	%if 0
	.3D_FRAME:
		dq 0 ; number of nodes (6 DOF per node)
		dq 0 ; number of elements
		dq 0 ; number of element types
		dq 0 ; pointer to node coordinate array
			; each row: (double) x,y,z
		dq 0 ; pointer to element array 
			; each row: (long) nodeID_A,nodeID_B,elementType
		dq 0 ; pointer to element type matrix
			; each row (double) E,G,A,Iy,Iz,J,Vx,Vy,Vz
		dq 0 ; pointer to stiffness matrix (K)
		dq 0 ; pointer to known forcing array (F)
		dq 0 ; pointer to unknown DoF array (U)
	%endif

	; initialize heap if not already
	call heap_init
	
	; allocate space for 3D frame system
	push rdi
	mov rdi,72
	call heap_alloc ; 3D frame system at {rax}
	pop rdi
	
	; compute number of nodes
	mov r15,rdi
	push rsi
	dec rsi
	imul r15,rsi
	test rsi,1
	jnz .even_rung_elements
	inc r15
.even_rung_elements:
	push rdi
	push rdx
	inc rdi
	imul rdi,rdx
	inc rdi
	shl rdi,1
	add r15,rdi
	pop rdx
	pop rdi	
	pop rsi
	mov [rax+0],r15
	
	; compute number of elements
	push rdi
	push rsi
	push rdx
	imul rsi,rdi
	inc rdi
	imul rdi,rdx
	shl rdi,1
	add rdi,rsi
	mov [rax+8],rdi
	pop rsi
	pop rdx

	; store number of element types
	mov r15,2
	mov [rax+16],r15

	; allocate space for node array
	mov r15,rax
	mov rdi,[rax+0]
	imul rdi,rdi,24
	call heap_alloc
	mov [r15+24],rax

	; allocate space for element array
	mov rdi,[r15+8]
	imul rdi,24
	call heap_alloc
	mov [r15+32],rax

	; allocate space for element type matrix
	mov rdi,144
	call heap_alloc
	mov [r15+40],rax

	; allocate space for stiffness matrix (K)
	mov rdi,[r15+0]
	imul rdi,rdi
	imul rdi,rdi,288
	call heap_alloc
	mov [r15+48],rax

	; allocate space for known forcing matrix (F)
	mov rdi,[r15+0]
	imul rdi,48
	call heap_alloc
	mov [r15+56],rax

	; allocate space for unknown DoF matrix (U)
	call heap_alloc
	mov [r15+64],rax
	mov rax,r15
	pop rdi

	; populate element type matrix
	mov r15,[rax+40]
	mov [r15+0],r12 ; E
	mov [r15+72],r12
	mov [r15+8],r13 ; G
	mov [r15+80],r13
	mov r12,[.zero]
	mov r13,[.one]
	mov [r15+48],r12 ; Vx
	mov [r15+56],r13 ; Vy
	mov [r15+64],r12 ; Vz
	mov [r15+120],r12 ; Vx
	mov [r15+128],r13 ; Vy
	mov [r15+136],r12 ; Vz
	movq xmm0,r9
	mulsd xmm0,[.half]
	mulsd xmm0,xmm0
	mulsd xmm0,[.pi]
	movq [r15+16],xmm0 ; A
	movq xmm0,r9
	mulsd xmm0,xmm0
	mulsd xmm0,xmm0
	mulsd xmm0,[.sixtyfourth]
	mulsd xmm0,[.pi]
	movq [r15+24],xmm0 ; Iy
	movq [r15+32],xmm0 ; Iz
	addsd xmm0,xmm0
	movq [r15+40],xmm0 ; J
	movq xmm0,r10
	movq xmm1,r11
	mulsd xmm0,xmm1
	movq [r15+88],xmm0 ; A
	mulsd xmm0,xmm1
	mulsd xmm0,xmm1
	mulsd xmm0,[.twelfth]
	movq [r15+96],xmm0 ; Iy
	movq xmm0,r10
	movsd xmm2,xmm0
	mulsd xmm0,xmm2
	mulsd xmm0,xmm2
	mulsd xmm0,xmm1
	mulsd xmm0,[.twelfth]
	movq [r15+104],xmm0 ; Iz 
	movq xmm1,[r15+96]
	addsd xmm0,xmm1
	movq [r15+112],xmm0 ; J

	; populate the node coordinate array
		; right rail
	mov r15,[rax+24]
	movq xmm2,r8 ; L
	movq xmm0,r14
	mulsd xmm0,[.convert_deg_to_radians]
	movq xmm1,[.tolerance]
	call sine
	mulsd xmm0,xmm2
	movsd xmm3,xmm0 ; Lsin(theta)
	movq xmm0,r14
	mulsd xmm0,[.convert_deg_to_radians]
	movq xmm1,[.tolerance]
	call cosine
	mulsd xmm0,xmm2
	movsd xmm4,xmm0 ; Lcos(theta)

	push rcx
	movq xmm5,rcx
	mulsd xmm5,[.half] ; +x dimension for side rails
	movsd xmm6,xmm5
	mulsd xmm6,[.neg_one] ; -x dimension for side rails
	mov rcx,rdi
	inc rcx
	imul rcx,rdx
	cvtsi2sd xmm2,rcx ; # nodes on rail (-1)
	movsd xmm7,xmm4
	divsd xmm7,xmm2	; Lcos(theta)/N
	
	movsd xmm8,xmm3
	divsd xmm8,xmm2 ; Lsin(theta)/N

	pxor xmm9,xmm9

.loop_right_rail_nodes:
	; Z starts at zero (xmm9) an increases by xmm8
	; Y starts at Lcos(theta) (xmm4) and decreases by xmm7
	; X is xmm5 for the positive rail and xmm6 for the negative rail

	movq [r15+0],xmm5
	movq [r15+8],xmm4
	movq [r15+16],xmm9
	movq [r15+24],xmm6
	movq [r15+32],xmm4
	movq [r15+40],xmm9

	addsd xmm9,xmm8
	subsd xmm4,xmm7
	add r15,48

	dec rcx
	jns .loop_right_rail_nodes	

	; rung nodes
	mov rcx,rdi

	movq xmm2,r8 ; L
	movq xmm0,r14
	mulsd xmm0,[.convert_deg_to_radians]
	movq xmm1,[.tolerance]
	call sine
	mulsd xmm0,xmm2
	movsd xmm3,xmm0 ; Lsin(theta)
	movq xmm0,r14
	mulsd xmm0,[.convert_deg_to_radians]
	movq xmm1,[.tolerance]
	call cosine
	mulsd xmm0,xmm2
	movsd xmm4,xmm0 ; Lcos(theta)

	inc rcx
	cvtsi2sd xmm2,rcx ; # segments
	movsd xmm7,xmm4
	divsd xmm7,xmm2	; Lcos(theta)/N
	
	movsd xmm8,xmm3
	divsd xmm8,xmm2 ; Lsin(theta)/N

	pxor xmm9,xmm9 
	pxor xmm0,xmm0 ; temporary x value, TODO: change with more elements per rung

	dec rcx
	addsd xmm9,xmm8
	subsd xmm4,xmm7
	
.loop_rungs:

	; eventually add logic to handle ~=2 elements per rung	

.loop_rung_elements: ; unused for now

	movq [r15+0],xmm0
	movq [r15+8],xmm4
	movq [r15+16],xmm9

	addsd xmm9,xmm8
	subsd xmm4,xmm7
	add r15,24

	dec rcx
	jnz .loop_rungs	

	pop rcx

	push rcx
	push rdx
	push r8

	mov rcx,rdi
	inc rcx
	imul rcx,rdx
	mov r15,[rax+32]
	xor rdx,rdx
	mov r8,1

.right_rail_elements:
	
	mov [r15+0],rdx
	add rdx,2
	mov [r15+8],rdx
	mov [r15+16],r8 ; element type for side rails
	add r15,24
	
	dec rcx
	jnz .right_rail_elements

	mov rcx,rdi
	inc rcx
	mov rdx,[rsp+8]
	imul rcx,rdx
	mov rdx,1

.left_rail_elements:
	
	mov [r15+0],rdx
	add rdx,2
	mov [r15+8],rdx
	mov [r15+16],r8 ; element type for side rails
	add r15,24
	
	dec rcx
	jnz .left_rail_elements

	inc rdx
	mov r10,rdx ; r10 is first rung "middle" element

	pop r8
	pop rdx
	pop rcx

	; now we do elements along rungs from top to bottom

	push rcx
	push r8
	push r9
	push r11

	; r10 is first rung "middle" element	
	mov rcx,rdi ; rung count
	mov r8,rdx 
	shl r8,1 ; r8 tracks starting right right node #
	mov r9,r8 ; r9 tracks distance between rung start nodes (right)
	dec r9
	xor r11,r11 ; rung element type

	; update this later to support >2 els/rung (TODO)

.rung_loop:
	
	mov [r15+0],r8
	mov [r15+8],r10
	mov [r15+16],r11 ; element type for rungs

	mov [r15+24],r10
	inc r8
	mov [r15+32],r8
	mov [r15+40],r11 ; element type for rungs

	inc r10
	add r8,r9
	add r15,48

	dec rcx
	jnz .rung_loop

	; generate stiffness matrix without boundary conditions
	push rax
	push rdi
	mov rdi,rax
	call assemble_frame_elements
	pop rdi
	pop rax

	; impose boundary conditions
	mov rcx,rdi
	inc rcx
	imul rcx,rdx
	imul rcx,rcx,12 ; need to zero 12 DOFs starting at DOF {rcx}

	mov r8,[rax+0]
	imul r8,r8,6	; # DOFs
	mov r9,[rax+48] ; K 
	mov r11,r8
	shl r11,3	; width of K matrix
	mov r12,r11
	imul r12,rcx
	add r9,r12	; start of row for first DOF to set
	
	mov r13,12
	movsd xmm0,[.one]
	xor r15,r15
	
	push rdi
	push rsi
	push rdx
	mov rdx,r11

.set_dofs_loop:

	; set column loop
	mov r14,r8	
	mov rdi,rcx
	shl rdi,3
	add rdi,[rax+48]
.set_dofs_column:
	mov [rdi],r15
	add rdi,r11
	dec r14
	jnz .set_dofs_column

	mov rdi,r9
	xor sil,sil
	call memset

	mov rsi,rcx
	shl rsi,3
	add rdi,rsi
	movq [rdi],xmm0

	add r9,r11
	inc rcx
	dec r13
	jnz .set_dofs_loop

	; zero Z deflection for nodes 0 and 1 (DOF #2 and #8)
	mov rcx,2*8
	add rcx,[rax+48]
	mov r13,r8

.loop_Z_dofs_1:
	mov [rcx],r15
	add rcx,r11
	dec r13
	jnz .loop_Z_dofs_1


	mov rcx,8*8
	add rcx,[rax+48]
	mov r13,r8
.loop_Z_dofs_2:
	mov [rcx],r15
	add rcx,r11
	dec r13
	jnz .loop_Z_dofs_2

	mov rdx,r11
	mov rdi,r11
	imul rdi,rdi,2
	add rdi,[rax+48]
	xor sil,sil
	call memset
	mov rdi,r11
	imul rdi,rdi,8
	add rdi,[rax+48]
	call memset

	mov rdi,2
	imul rdi,r11
	add rdi,[rax+48]
	add rdi,2*8
	movq [rdi],xmm0
	mov rdi,8
	imul rdi,r11
	add rdi,[rax+48]
	add rdi,8*8
	movq [rdi],xmm0

	pop rdx
	pop rsi
	pop rdi

	; impose force
	mov rcx,rdi
	inc rcx
	imul rcx,rdx
	shl rcx,1
	add rcx,2
	imul rcx,rcx,6 
	inc rcx ; Y-force to set at DOF {rcx}
	shl rcx,3
	mov r9,[rax+56] ; F 
	add r9,rcx	; address of DOF to set
	movsd xmm0,[.weight]
	movq [r9],xmm0

	pop r11
	pop r9
	pop r8
	pop rcx

	ret

.neg_one:
	dq -1.0
.zero:
	dq 0.0
.half:
	dq 0.5
.sixtyfourth:
	dq 0.015625
.one:
	dq 1.0
.pi:
	dq 3.14159265359
.weight:
	dq -200.0
.twelfth:
	dq 0.08333333333
.convert_deg_to_radians:
	dq 0.01745329251
.tolerance:
	dq 0.000001

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
	
	; generate ladder system (nodes and elements)
	mov rdi,[.number_rungs]
	mov rsi,[.number_elements_per_rung]
	mov rdx,[.number_side_rail_elements_between_rungs]
	mov rcx,[.rung_length]
	mov r8,[.side_rail_length]
	mov r9,[.rung_diameter]
	mov r10,[.side_rail_cross_sectional_width]
	mov r11,[.side_rail_cross_sectional_height]
	mov r12,[.E]
	mov r13,[.G]
	mov r14,[.ladder_angle_deg]
	call GENERATE_LADDER_SYSTEM

	push rax
	mov rdi,[rax+0]
	imul rdi,rdi,48
	call heap_alloc
	mov r8,rax	; pivoting vector
	mov rax,[rsp+0]

	; solve the linear system
	mov rdi,[rax+64]
	mov rsi,[rax+48]
	mov rdx,[rax+56]
	mov rcx,[rax+0]
	imul rcx,rcx,6
	; pivot vector space at {r8}
	call plu_solve

	mov rdi,r8
	call heap_free

	pop rax	

	; populate the rendering items
	mov rbx,[rax+0]	
	mov [.undeformed_element_structure+0],rbx
	mov [.deformed_element_structure+0],rbx
	mov [.undeformed_node_structure+0],rbx
	mov [.deformed_node_structure+0],rbx
	mov rbx,[rax+8]	
	mov [.undeformed_element_structure+8],rbx
	mov [.deformed_element_structure+8],rbx
	mov rbx,[rax+24]	
	mov [.undeformed_element_structure+16],rbx
	mov [.undeformed_node_structure+8],rbx

	push rax
	mov rdi,[rax+8]
	shl rdi,4
	call heap_alloc
	mov r8,rax ; r8 points to start of new edge list
	mov [.undeformed_element_structure+24],rax
	mov [.deformed_element_structure+24],rax
	pop rax

	mov r9,[rax+32] ; r9 points to start of element node list
	mov rcx,[rax+8] ; element counter

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
	push rax
	mov rdi,[rax+0]
	imul rdi,rdi,24
	call heap_alloc
	mov r8,rax ; r8 points to start of new node array
	mov [.deformed_element_structure+16],rax
	mov [.deformed_node_structure+8],rax
	pop rax
	mov rsi,[rax+24]
	mov rdx,[rax+64]

	movsd xmm2,[.displacement_scale_factor]
	mov rdi,[rax+0]
.deformed_node_position_loop:

	movq xmm0,[rsi+0]
	movq xmm1,[rdx+0]
	mulsd xmm1,xmm2
	addsd xmm0,xmm1
	movq [r8+0],xmm0
	
	movq xmm0,[rsi+8]	
	movq xmm1,[rdx+8]
	mulsd xmm1,xmm2
	addsd xmm0,xmm1
	movq [r8+8],xmm0

	movq xmm0,[rsi+16]
	movq xmm1,[rdx+16]
	mulsd xmm1,xmm2
	addsd xmm0,xmm1
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


align 16
.displacement_scale_factor:
	dq 500.0
.number_rungs:
	dq 8
.number_elements_per_rung:
	dq 2
.number_side_rail_elements_between_rungs:
	dq 2
.rung_length:
	dq 2.0
.side_rail_length:
	dq 10.0
.rung_diameter:
	dq 1.0
.side_rail_cross_sectional_width:
	dq 1.0
.side_rail_cross_sectional_height:
	dq 2.0
.E:
	dq 1000000.0
.G:
	dq 1000000.0
.ladder_angle_deg:
	dq 30.0

align 16

.perspective_structure:
	dq 0.00 ; lookFrom_x	
	dq 4.00 ; lookFrom_y	
	dq 5.00 ; lookFrom_z	
	dq 0.00 ; lookAt_x	
	dq 4.00 ; lookAt_y	
	dq 0.00 ; lookAt_z	
	dq 0.0 ; upDir_x	
	dq 1.0 ; upDir_y	
	dq 0.0 ; upDir_z	
	dq 0.1	; zoom

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

