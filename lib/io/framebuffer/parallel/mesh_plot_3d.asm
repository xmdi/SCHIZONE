%ifndef MESH_PLOT_3D
%define MESH_PLOT_3D

; input data structures
%if 0

; this is what you pass to the plot_axis_3d.asm function
.plot_structure:
	dq .plot_title; address of null-terminated title string {*+0}
	dq .plot_xlabel; address of null-terminated x-label string {*+8}
	dq .plot_ylabel; address of null-terminated y-label string {*+16}
	dq .plot_zlabel; address of null-terminated z-label string {*+24}
	dq .mesh_dataset_structure1; addr of linked list for datasets {*+32}
	dq 0.0; plot origin x translation (double) {*+40}
	dq 0.0; plot origin y translation (double) {*+48}
	dq 0.0; plot origin z translation (double) {*+56}
	dq 0.0; origin x-coord (double) {*+64}
	dq 0.0; origin y-coord (double) {*+72}
	dq 0.0; origin z_coord (double) {*+80}
	dq -5.0; x-min (double) {*+88}
	dq 5.0; x-max (double) {*+96}
	dq -6.0; y-min (double) {*+104}
	dq 6.0; y-max (double) {*+112}
	dq -7.0; z-min (double) {*+120}
	dq 7.0; z-max (double) {*+128}
	dq 0; title x-coordinate {*+136}
	dq 0; title y-coordinate {*+144}
	dq 0; title z-coordinate {*+152}
	dd 0x000000; #XXXXXX RGB x-axis color {*+160}
	dd 0x000000; #XXXXXX RGB y-axis color {*+164}
	dd 0x000000; #XXXXXX RGB z-axis color {*+168}
	dd 0x000000; #XXXXXX title RGB font color {*+172}
	db 11; number of major x-ticks {*+176}
	db 5; number of major y-ticks {*+177}
	db 5; number of major z-ticks {*+178}
	db 2; minor subdivisions per x-tick {*+179}
	db 2; minor subdivisions per y-tick {*+180}
	db 2; minor subdivisions per z-tick {*+181}
	db 2; significant digits on x values {*+182}
	db 2; significant digits on y values {*+183}
	db 2; significant digits on z values {*+184}
	db 32; title font size (px) {*+185}
	db 24; axis label font size (px) {*+186}
	db 16; tick label font size (px) {*+187}
	dq 1.0; y-offset for x-tick labels {*+188}
	dq -1.0; z-offset for y-tick labels {*+196}
	dq -1.0; x-offset for z-tick labels {*+204}
	db 2; axis & tick stroke thickness (px) (0 disables axis) {*+212}
	db 5; x-tick fraction (/255) {*+213}
	db 5; y-tick fraction (/255) {*+214}
	db 5; z-tick fraction (/255) {*+215}
	db 0x1F; flags: {*+216}
		; bit 0 (LSB)	= show title?
		; bit 1		= show x-label?
		; bit 2		= show y-label?
		; bit 3		= show z-label?
		; bit 4		= draw ticks?
		; bit 5		= show tick labels?

; this is what this function takes as an argument
.mesh_dataset_structure1:
	dq 0; address of next dataset in linked list {*+0}
	dq 0; address of null-terminated label string, currently unused {*+8}
	dq .nodes; address of first (x,y,z) coordinate set (quadwords) {*+16}
	dw 0; extra stride between node {*+24}
	dq .elements; address of first element {*+26}
	dw 0; extra stride between elements (quadword) {*+34}	
	dq .colors; address of first node color (doubleword) {*+36}
	dw 0; extra stride between colors {*+44}
	dd 101; number of nodes {*+46}
	dd 101; number of elements {*+50}
	dd 0xFF0000; default #XXXXXX RGB marker color {*+54}
	db 2 ; nodes per element (only supports certain values) {*+58}
	db 2 ; line thickness {*+59}
	db 0x00; flags {*+60}

%endif

%include "lib/mem/heap_alloc.asm"
%include "lib/mem/memcopy.asm"

mesh_plot_3d:
; struct* {rax} mesh_plot_3d(struct* {rdi});
;	Converts input 3D mesh plot definition linked structures at {rdi} into
;	renderable 3D graphics structures linked together returned in {rax}. 

	push r15
	push r14
	push rbx
	push rcx
	push rsi
	push rdi

	mov r14,rdi ; mesh_structure
	mov [.pointer_for_meshset],rbx

.mesh_set_loop:
	; mesh point struct population

	; check if the stride is zero, if so skip all this nonsense
	movzx rax,word [r14+24]
	cmp rax,0
	jne .node_struct_required	

	mov rax,[r14+16]
	mov [.node_array_address],rax

	jmp .no_node_struct_required

.node_struct_required:
	
	; node struct
	xor rdi,rdi
	mov edi,dword [r14+46]
	mov rcx,rdi
	cmp rcx,0
	je .died

	imul rdi,rdi,24
	call heap_alloc
	jz .died

	mov rdi,rax
	mov [.node_array_address],rax

	mov rdx,24
	mov rsi,[r14+16]
	movzx rax,word [r14+24]

.node_coord_copy_loop:

	call memcopy
	add rdi,24
	add rsi,24
	add rsi,rax
	dec rcx
	jnz .node_coord_copy_loop
	
.no_node_struct_required:

	xor rcx,rcx
	mov ecx,dword [r14+50] ; num elements
	movzx rdx,byte [r14+58] ; num nodes per element

	cmp rdx,2
	jl .died	; bogus nodes/el
	je .line_element

.other_element:
	; reserve enough space
	mov rdi,rcx
	imul rdi,rdx ; num of nodes to list for pairs
	shl rdi,4 ; *=16 bytes per pair	

	call heap_alloc
	jz .died

	; edge struct
	mov rdi,33
	call heap_alloc

	test rax,rax
	jz .died

.line_element:

	; reserve enough space
	mov rdi,16 ; *=16 bytes per pair	
	call heap_alloc
	jz .died

	mov [.element_array_address],rax
	mov rdi,rax	; pointer to destination
	mov rsi,[r14+26] ; pointer to first element set
	; pair stuff here, {rcx} contains number of elements
.line_element_pair_loop:
	; transfer nodes here	
	mov rax,[rsi+0]
	mov [rdi+0],rax
	mov rax,[rsi+8]
	mov [rdi+8],rax
	add rdi,16
	add rsi,16	
	dec rcx
	jnz .line_element_pair_loop

	; wire struct
	mov rdi,33
	call heap_alloc

	test rax,rax
	jz .died

	mov [.wire_struct_address],rax
	
	mov ecx,dword [r14+46] ; num nodes
	mov [rax+0],rcx
	
	mov ecx,dword [r14+50] ; num elements
	mov [rax+8],rcx

	mov rbx,[.node_array_address]
	mov [rax+16],rbx ; points list

	mov rbx,[.element_array_address]
	mov [rax+24],rbx ; edges list
	
	mov bl,[r15+212] ; thickness
	mov byte [rax+32],bl

	; geom struct
	mov rdi,25
	call heap_alloc

	test rax,rax
	jz .died

	mov rbx,[.wire_struct_address] ; wire substruct
	mov [rax+8],rbx

	mov bl,0b1001 ; type of wire
	mov byte [rax+24],bl

	mov [.geometry_struct_address],rax

.died:
	pop rdi
	pop rsi
	pop rcx
	pop rbx
	pop r14
	pop r15

	ret

.geometry_struct_address:
	dq 0

.wire_struct_address:
	dq 0

.node_array_address:
	dq 0

.element_array_address:
	dq 0

.pointer_for_meshset:
	dq 0

%endif
