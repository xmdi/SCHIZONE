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
	db 0x00; flags, currently unused: {*+86}

%endif

%include "lib/io/bitmap/SCHIZOFONT.asm"
%include "lib/io/print_float.asm"
%include "lib/io/print_buffer_reset.asm"
%include "lib/io/print_buffer_flush_to_memory.asm"
%include "lib/mem/memset.asm"
%include "lib/mem/heap_alloc.asm"

scatter_plot_3d:
; struct* {rax} scatter_plot_3d(struct* {rdi});
;	Converts input 3D scatter plot definition structures into renderable
; 	3D graphics structures linked together returned in {rax}. 
; 	WARNING: prematurely flushes print buffer.

	push r15
	push r14
	push rbx
	push rcx

	call print_buffer_reset

	mov r15,rdi

	xor rax,rax
	mov [.num_textboxes],rax

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
	add [.num_textboxes],rbx
	movzx rcx,byte [r15+179] ; subdivisions per x tick
	
	mov rdi,rbx
	dec rdi
	imul rdi,rcx
	inc rdi		; number of major and minor x ticks

	mov rax,rdi

	movzx rbx,byte [r15+177] ; major y ticks
	add [.num_textboxes],rbx
	movzx rcx,byte [r15+180] ; subdivisions per y tick
	
	mov rdi,rbx
	dec rdi
	imul rdi,rcx
	inc rdi		; number of major and minor y ticks

	add rax,rdi

	movzx rbx,byte [r15+178] ; major z ticks
	add [.num_textboxes],rbx
	movzx rcx,byte [r15+181] ; subdivisions per z tick
	
	mov rdi,rbx
	dec rdi
	imul rdi,rcx
	inc rdi		; number of major and minor z ticks

	add rdi,rax 	; total ticks in all directions

	mov [.num_grid_edges],rdi

	imul rdi,rdi,24

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

	; x grid starts here

	movzx rbx,byte [r15+176] ; major x ticks
	movzx rcx,byte [r15+179] ; subdivisions per x tick
	
	; tracking x y z in xmm0,xmm1,xmm2
	movsd xmm0,[r15+88] ; xmin
	movsd xmm1,[r15+72] ; yO
	movsd xmm2,[r15+80] ; zO

	movsd xmm4,[r15+96]
	subsd xmm4,xmm0

	; check	
	mov rdi,rbx
	dec rdi
	imul rdi,rcx

	cvtsi2sd xmm5,rdi
	divsd xmm4,xmm5  	; delta x
	
	movzx rbx, byte [r15+213]
	cvtsi2sd xmm5,rbx
	mulsd xmm5,[.byte_fraction]
	movsd xmm6,[r15+112] ; ymax
	subsd xmm6,[r15+104] ; ymin
	mulsd xmm5,xmm6 	; semi tick length

	xor r12,r12

	inc rdi

.loop_ticks_x:
			
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

	addsd xmm0,xmm4
	
	dec rdi
	jnz .loop_ticks_x

	; TODO: check for at least one tick mark in y

	movzx rbx,byte [r15+177] ; major y ticks
	movzx rcx,byte [r15+180] ; subdivisions per y tick

	; tracking x y z in xmm0,xmm1,xmm2
	movsd xmm0,[r15+64] ; x0
	movsd xmm1,[r15+104] ; ymin
	movsd xmm2,[r15+80] ; zO

	movsd xmm4,[r15+112] ; ymax
	subsd xmm4,xmm1

	; check	
	mov rdi,rbx
	dec rdi
	imul rdi,rcx

	cvtsi2sd xmm5,rdi
	divsd xmm4,xmm5  	; delta y
	
	movzx rbx, byte [r15+214]
	cvtsi2sd xmm5,rbx
	mulsd xmm5,[.byte_fraction]
	movsd xmm6,[r15+128] ; zmax
	subsd xmm6,[r15+120] ; zmin
	mulsd xmm5,xmm6 	; semi tick length

	inc rdi

.loop_ticks_y:
			
	movsd xmm6,xmm2
	addsd xmm6,xmm5
	; put point1 at (xmm0,xmm1,xmm6)
	movsd [r14],xmm0
	movsd [r14+8],xmm1
	movsd [r14+16],xmm6

	movsd xmm6,xmm2
	subsd xmm6,xmm5
	; put point2 at (xmm0,xmm1,xmm6)
	movsd [r14+24],xmm0
	movsd [r14+32],xmm1
	movsd [r14+40],xmm6

	add r14,48
	
	mov [r13],r12 ; populates first edge pair and color
	inc r12
	mov [r13+8],r12
	mov ebx, dword [r15+164]
	mov [r13+16],rbx
	inc r12
	add r13,24

	addsd xmm1,xmm4
	
	dec rdi
	jnz .loop_ticks_y

	; TODO: check for at least one tick mark in z

	movzx rbx,byte [r15+178] ; major z ticks
	movzx rcx,byte [r15+181] ; subdivisions per z tick

	; tracking x y z in xmm0,xmm1,xmm2
	movsd xmm0,[r15+64] ; x0
	movsd xmm1,[r15+72] ; y0
	movsd xmm2,[r15+120] ; zmin

	movsd xmm4,[r15+128] ; zmax
	subsd xmm4,xmm2

	; check	
	mov rdi,rbx
	dec rdi
	imul rdi,rcx

	cvtsi2sd xmm5,rdi
	divsd xmm4,xmm5  	; delta z
	
	movzx rbx, byte [r15+215]
	cvtsi2sd xmm5,rbx
	mulsd xmm5,[.byte_fraction]
	movsd xmm6,[r15+96] ; xmax
	subsd xmm6,[r15+88] ; xmin
	mulsd xmm5,xmm6 	; semi tick length

	inc rdi

.loop_ticks_z:
			
	movsd xmm6,xmm0
	addsd xmm6,xmm5
	; put point1 at (xmm6,xmm1,xmm2)
	movsd [r14],xmm6
	movsd [r14+8],xmm1
	movsd [r14+16],xmm2

	movsd xmm6,xmm0
	subsd xmm6,xmm5
	; put point2 at (xmm6,xmm1,xmm2)
	movsd [r14+24],xmm6
	movsd [r14+32],xmm1
	movsd [r14+40],xmm2

	add r14,48
	
	mov [r13],r12 ; populates first edge pair and color
	inc r12
	mov [r13+8],r12
	mov ebx, dword [r15+168]
	mov [r13+16],rbx
	inc r12
	add r13,24

	addsd xmm2,xmm4
	
	dec rdi
	jnz .loop_ticks_z

	; grid wire struct
	mov rdi,33
	call heap_alloc
	
	test rax,rax
	jz .died
	
	mov rbx,[.num_grid_edges] ; num edges
	mov [rax+8],rbx

	shl rbx,1
	mov [rax+0],rbx ; num points

	mov rbx,[.grid_point_list_array_address]
	mov [rax+16],rbx ; points list

	mov rbx,[.grid_edge_list_array_address]
	mov [rax+24],rbx ; edges list
	
	mov bl,[r15+212] ; axis thickness
	mov byte [rax+32],bl

	mov [.grid_wire_struct_address],rax

	; grid geom struct
	mov rdi,25
	call heap_alloc

	test rax,rax
	jz .died

	mov rbx,[.grid_wire_struct_address] ; wire substruct
	mov [rax+8],rbx

	mov bl,0b1001 ; type of wire
	mov byte [rax+24],bl

	mov [.grid_geometry_struct_address],rax

	mov rbx,[.axis_geometry_struct_address]

	mov [rbx],rax

.no_grid:
%if 0
	mov bl, byte [r15+216]
	test bl,0b1
	jz .no_title_text
	inc qword [.num_textboxes]
.no_title_text:	
	test bl,0b10
	jz .no_x_text
	inc qword [.num_textboxes]
.no_x_text:	
	test bl,0b10
	jz .no_y_text
	inc qword [.num_textboxes]
.no_y_text:
	test bl,0b100
	jz .no_z_text
	inc qword [.num_textboxes]
.no_z_text:	
%endif

	mov rdi,[.num_textboxes]
	imul rdi,rdi,36
	call heap_alloc
	test rax,rax
	jz .died

	mov [.pointcloud_array_address],rax

	mov rdi,32
	call heap_alloc
	test rax,rax
	jz .died
	mov [.pointcloud_struct_address],rax

	mov rdi,25
	call heap_alloc
	test rax,rax
	jz .died
	mov [.pointcloud_geometry_address],rax


	xor rbx,rbx
	mov [rax+0],rbx
	mov rbx,[.pointcloud_struct_address]
	mov [rax+8],rbx
	mov rbx,0b11
	mov byte [rax+24],bl

	mov rax,[.pointcloud_struct_address]
	mov rbx,SCHIZOFONT
	mov [rax+16],rbx
	xor rbx,rbx
	movzx rbx,byte [r15+187]
	mov [rax+24],rbx
	mov rbx,[.pointcloud_array_address]
	mov [rax+0],rbx	
	mov rbx,[.num_textboxes]
	mov [rax+8],rbx

	mov rax,[.pointcloud_geometry_address]
	mov rbx,[.grid_geometry_struct_address]
	mov [rbx],rax

	; grid tick labels start here

	mov r14,[.pointcloud_array_address]

	; x grid tick labels start here
	
	movzx rbx,byte [r15+176] ; major x ticks
	
	; tracking x y z in xmm0,xmm1,xmm2
	movsd xmm0,[r15+88] ; xmin
	movsd xmm1,[r15+72] ; yO
	addsd xmm1,[r15+188] ; yO + tick label offset
	movsd xmm2,[r15+80] ; zO

	movsd xmm4,[r15+96]
	subsd xmm4,xmm0

	; check	
	mov rdi,rbx
	dec rdi

	cvtsi2sd xmm5,rdi
	divsd xmm4,xmm5  	; delta x

	inc rdi

.loop_tick_labels_x:
			
	; put text at (xmm0,xmm1,xmm2)
	movsd [r14],xmm0
	movsd [r14+8],xmm1
	movsd [r14+16],xmm2

	push rdi
	push rsi
	push rdx
	push rax
	; for y and z will have to push/pop xmm0

	movzx rdi,byte [r15+182] ; x sig dig
	add rdi,8 		; extra digits
	call heap_alloc
	test rax,rax
	jz .died

	mov qword [r14+24],rax

	mov rdx,rdi
	xor rsi,rsi
	mov rdi,rax	
	call memset

	mov rdi,rax
	movzx rsi, byte [r15+182]
;	movsd xmm0,
	call print_float	

	call print_buffer_flush_to_memory

	pop rax
	pop rdx
	pop rsi
	pop rdi

;	mov qword [r14+24],.kek
	mov ebx,dword [r15+160]
	mov dword [r14+32],ebx

	add r14,36

	addsd xmm0,xmm4

	dec rdi
	jnz .loop_tick_labels_x

	; y grid tick labels start here
	
	movzx rbx,byte [r15+177] ; major y ticks

	; tracking x y z in xmm0,xmm1,xmm2
	movsd xmm0,[r15+64] ; x0
	movsd xmm1,[r15+104] ; ymin
	movsd xmm2,[r15+80] ; z0
	addsd xmm2,[r15+196] ; zO + tick label offset

	movsd xmm4,[r15+112]
	subsd xmm4,xmm1

	; check	
	mov rdi,rbx
	dec rdi

	cvtsi2sd xmm5,rdi
	divsd xmm4,xmm5  	; delta x

	inc rdi

.loop_tick_labels_y:
			
	; put text at (xmm0,xmm1,xmm2)
	movsd [r14],xmm0
	movsd [r14+8],xmm1
	movsd [r14+16],xmm2
	
	push rdi
	push rsi
	push rdx
	push rax
	sub rsp,16
	movdqu [rsp+0],xmm0

	movzx rdi,byte [r15+183] ; y sig dig
	add rdi,8 		; extra digits
	call heap_alloc
	test rax,rax
	jz .died

	mov qword [r14+24],rax

	mov rdx,rdi
	xor rsi,rsi
	mov rdi,rax	
	call memset

	mov rdi,rax
	movzx rsi, byte [r15+183]
	movsd xmm0,xmm1
	call print_float	

	call print_buffer_flush_to_memory

	movdqu xmm0,[rsp+0]
	add rsp,16
	pop rax
	pop rdx
	pop rsi
	pop rdi

	;mov qword [r14+24],.kek
	mov ebx,dword [r15+164]
	mov dword [r14+32],ebx
	
	add r14,36

	addsd xmm1,xmm4
	
	dec rdi
	jnz .loop_tick_labels_y

	; z grid tick labels start here
	
	movzx rbx,byte [r15+178] ; major z ticks
	
	; tracking x y z in xmm0,xmm1,xmm2
	movsd xmm0,[r15+64] ; x0 
	addsd xmm0,[r15+204] ; xO + tick label offset
	movsd xmm1,[r15+72] ; yO
	movsd xmm2,[r15+120] ; zmin

	movsd xmm4,[r15+128]
	subsd xmm4,xmm2

	; check	
	mov rdi,rbx
	dec rdi

	cvtsi2sd xmm5,rdi
	divsd xmm4,xmm5  	; delta x

	inc rdi

.loop_tick_labels_z:
			
	; put text at (xmm0,xmm1,xmm2)
	movsd [r14],xmm0
	movsd [r14+8],xmm1
	movsd [r14+16],xmm2

	push rdi
	push rsi
	push rdx
	push rax
	sub rsp,16
	movdqu [rsp+0],xmm0

	movzx rdi,byte [r15+184] ; z sig dig
	add rdi,8 		; extra digits
	call heap_alloc
	test rax,rax
	jz .died

	mov qword [r14+24],rax

	mov rdx,rdi
	xor rsi,rsi
	mov rdi,rax	
	call memset

	mov rdi,rax
	movzx rsi, byte [r15+184]
	movsd xmm0,xmm2
	call print_float	

	call print_buffer_flush_to_memory

	movdqu xmm0,[rsp+0]
	add rsp,16
	pop rax
	pop rdx
	pop rsi
	pop rdi

;	mov qword [r14+24],.kek
	mov ebx,dword [r15+168]
	mov dword [r14+32],ebx
	
	add r14,36

	addsd xmm2,xmm4
	
	dec rdi
	jnz .loop_tick_labels_z

.out:	

.no_axis:

	mov rax,[.axis_geometry_struct_address]

.died:
	pop rcx
	pop rbx
	pop r14
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

.num_grid_edges: ; 2x for points
	dq 0

.num_textboxes:
	dq 0

.pointcloud_array_address:
	dq 0

.pointcloud_struct_address:
	dq 0

.pointcloud_geometry_address:
	dq 0

.kek:
	db `kek`,0

align 8
.byte_fraction:
	dq 0x3F60101010101010 

%endif
