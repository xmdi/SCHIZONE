%ifndef SCATTER_PLOT_3D
%define SCATTER_PLOT_3D

; input data structures
%if 0

.scatter_plot_structure:
	dq .scatter_title; address of null-terminated title string {*+0}
	dq .scatter_xlabel; address of null-terminated x-label string {*+8}
	dq .scatter_ylabel; address of null-terminated y-label string {*+16}
	dq .scatter_zlabel; address of null-terminated z-label string {*+24}
	dq .scatter_dataset_structure1; addr of linked list for datasets {*+32}
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
	dq 0; legend x-coordinate {*+136}
	dq 0; legend y-coordinate {*+144}
	dq 0; legend z-coordinate {*+152}
	dd 0x000000; #XXXXXX RGB x-axis color {*+160}
	dd 0x000000; #XXXXXX RGB y-axis color {*+164}
	dd 0x000000; #XXXXXX RGB z-axis color {*+168}
	dd 0x000000; #XXXXXX title/legend RGB font color {*+172}
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
	db 16; tick & legend label font size (px) {*+187}
	dq 1.0; y-offset for x-tick labels {*+188}
	dq -1.0; x-offset for y-tick labels {*+196}
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
		; bit 6		= draw legend?

.scatter_dataset_structure1:
	dq 0; address of next dataset in linked list {*+0}
	dq .scatter_data_label_1; address of null-terminated label string {*+8}
	dq .x_coords; address of first x-coordinate {*+16}
	dw 0; extra stride between x-coord elements {*+24}
	dq .y_coords; address of first y-coordinate {*+26}
	dw 0; extra stride between y-coord elements {*+34}	
	dq .z_coords; address of first z-coordinate {*+36}
	dw 0; extra stride between z-coord elements {*+44}
	dq .marker0_colors; address of first marker color element {*+46}
	dw 0; extra stride between marker color elements {*+54}
	dq .marker0_sizes; address of first marker size element {*+56}
	dw 0; extra stride between marker size elements {*+64}
	dq .marker0_types; address of first marker type element {*+66}
	dw 0; extra stride between marker type elements {*+74}
	dd 101; number of elements {*+76}
	dd 0xFF0000; default #XXXXXX RGB marker color {*+80}
	db 5; default marker size (px) {*+84}
	db 5; default marker type (1-4) {*+85}
	db 0x01; flags: {*+86}
		; bit 0 (LSB)	= include in legend?

%endif

%include "lib/mem/heap_alloc.asm"

scatter_plot_3d:
; struct* {rax} scatter_plot_3d(struct* {rdi});
;	Converts input 3D scatter plot definition structures into renderable
; 	3D graphics structures linked together returned in {rax}. 

	push r15
	push rbx
	push rcx

	mov r15,rdi

	cmp byte [r15+212],0
	je .no_axis

	;;; create the axis structure	

	; axis point struct

	mov rdi,144
	call heap_alloc
	
	test rax,rax
	jz .died

	mov rbx,[r15+64] ; origin x
	mov [rax+48],rbx	
	mov [rax+72],rbx	
	mov [rax+96],rbx	
	mov [rax+120],rbx	

	mov rbx,[r15+72] ; origin y
	mov [rax+8],rbx	
	mov [rax+32],rbx	
	mov [rax+104],rbx	
	mov [rax+128],rbx	

	mov rbx,[r15+80] ; origin z
	mov [rax+16],rbx	
	mov [rax+40],rbx	
	mov [rax+64],rbx	
	mov [rax+88],rbx	

	mov rbx,[r15+88]
	mov [rax+0],rbx ; xmin x
	mov rbx,[r15+96]
	mov [rax+24],rbx ; xmax x
	
	mov rbx,[r15+104]
	mov [rax+56],rbx ; ymin y
	mov rbx,[r15+112]
	mov [rax+80],rbx ; ymax y
	
	mov rbx,[r15+120]
	mov [rax+112],rbx ; zmin z
	mov rbx,[r15+128]
	mov [rax+136],rbx ; zmax z
	
	mov [.axis_point_list_array_address],rax

	; axis edge struct
	mov rdi,72
	call heap_alloc

	test rax,rax
	jz .died

	xor rbx,rbx ; six coupled vertex pairs
	mov [rax+0],rbx
	inc rbx
	mov [rax+8],rbx
	inc rbx
	mov [rax+24],rbx
	inc rbx
	mov [rax+32],rbx
	inc rbx
	mov [rax+48],rbx
	inc rbx
	mov [rax+56],rbx

	mov ebx, dword [r15+160] ; x color
	mov dword [rax+16],ebx
	mov ebx, dword [r15+164] ; y color
	mov dword [rax+40],ebx
	mov ebx, dword [r15+168] ; z color
	mov dword [rax+64],ebx

	mov [.axis_edge_list_array_address],rax

	; axis wire struct
	mov rdi,33
	call heap_alloc

	test rax,rax
	jz .died

	mov rbx,6 ; num points
	mov [rax+0],rbx

	mov rbx,3 ; num edges
	mov [rax+8],rbx

	mov rbx,[.axis_point_list_array_address]
	mov [rax+16],rbx ; points list

	mov rbx,[.axis_edge_list_array_address]
	mov [rax+24],rbx ; edges list
	
	mov bl,[r15+212] ; axis thickness
	mov byte [rax+32],bl

	mov [.axis_wire_struct_address],rax

	; axis geom struct
	mov rdi,25
	call heap_alloc

	test rax,rax
	jz .died

	mov rbx,[.axis_wire_struct_address] ; wire substruct
	mov [rax+8],rbx

	mov bl,0b1001 ; type of wire
	mov byte [rax+24],bl

	mov [.axis_geometry_struct_address],rax


	; NOTE: tick marks to have their own rendering struct


	;;; create the grid structure	

	mov bl, byte [r15+216]
	test bl,0b10000
	jz .no_grid

	; TODO: check for at least one tick mark in x

	; grid point struct

	movzx rbx,byte [r15+176] ; major x ticks
	movzx rcx,byte [r15+179] ; subdivisions per x tick
	
	mov rdi,rbx
	dec rdi
	imul rdi,rcx
	inc rdi		; number of major and minor x ticks
	
	call heap_alloc
	mov [.grid_edge_list_array_address],rax
	test rax,rax
	jz .died
	mov r13,rax

	shl rdi,1
	call heap_alloc
	mov [.grid_point_list_array_address],rax
	test rax,rax
	jz .died
	mov r14,rax

	; tracking x y z in xmm0,xmm1,xmm2
	movsd xmm0,[r15+88] ; xmin
	movsd xmm1,[r15+72] ; yO
	movsd xmm2,[r15+80] ; zO

	movsd xmm4,[r15+96]
	subsd xmm4,xmm0
	movsd xmm6,xmm4
	shr rdi,1
	dec rdi
	cvtsi2sd xmm5,rdi
	divsd xmm4,xmm5  	; delta x
	
	movzx rbx, byte [r15+213]
	cvtsi2sd xmm5,rbx
	mulsd xmm5,[.byte_fraction]
	mulsd xmm5,xmm6 	; semi tick length

	movsd xmm6,xmm1
	addsd xmm6,xmm5
	; put point1 at (xmm0,xmm6,xmm2)
	movsd [r14],xmm0
	movsd [r14+8],xmm6
	movsd [r14+16],xmm2

	movsd xmm6,xmm1
	subsd xmm6,xmm5
	; put point2 at (xmm0,xmm6,xmm2)
	movsd [r14+24],xmm0
	movsd [r14+32],xmm6
	movsd [r14+40],xmm2

	add r14,48
	
	xor r12,r12
	
	mov [r13],r12 ; populates first edge pair and color
	inc r12
	mov [r13+8],r12
	mov ebx, dword [r15+160]
	mov [r13+16],rbx
	inc r12
	add r13,24

.loop_ticks_x:

	addsd xmm0,xmm4
			
	movsd xmm6,xmm1
	addsd xmm6,xmm5
	; put point1 at (xmm0,xmm6,xmm2)
	movsd [r14],xmm0
	movsd [r14+8],xmm6
	movsd [r14+16],xmm2

	movsd xmm6,xmm1
	subsd xmm6,xmm5
	; put point2 at (xmm0,xmm6,xmm2)
	movsd [r14+24],xmm0
	movsd [r14+32],xmm6
	movsd [r14+40],xmm2

	add r14,48
	
	mov [r13],r12 ; populates first edge pair and color
	inc r12
	mov [r13+8],r12
	mov ebx, dword [r15+160]
	mov [r13+16],rbx
	inc r12
	add r13,24

	dec rdi
	jnz .loop_ticks_x


.no_grid:
.no_axis:

	mov rax,[.axis_geometry_struct_address]

.died:
	pop rcx
	pop rbx
	pop r15

	ret


.axis_geometry_struct_address:
	dq 0

.axis_wire_struct_address:
	dq 0

.axis_point_list_array_address:
	dq 0

.axis_edge_list_array_address:
	dq 0

.grid_geometry_struct_address:
	dq 0

.grid_wire_struct_address:
	dq 0

.grid_point_list_array_address:
	dq 0

.grid_edge_list_array_address:
	dq 0

align 8
.byte_fraction:
	dq 0x3F60101010101010 

%endif
