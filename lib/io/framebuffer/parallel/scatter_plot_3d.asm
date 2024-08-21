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

.scatter_dataset_structure1:
	dq 0; address of next dataset in linked list {*+0}
	dq 0; address of null-terminated label string, currently unused {*+8}
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
%include "lib/io/framebuffer/parallel/plot_axis_3d.asm"

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

	cmp byte [r15+212],0
	je .no_axis
	
	call plot_axis_3d
	; {rax} points to the first element of the linked list
	mov [.axis_geometry_struct_address],rax
	
.find_end_of_linked_list:
	cmp qword [rax],0
	je .found_end_of_linked_list
	mov rax,[rax]
	jmp .find_end_of_linked_list
.found_end_of_linked_list:	
	mov [.axis_textcloud_geometry_address],rax

.no_axis:

	mov r14,[r15+32] ; scatter_dataset_structure
	mov rbx,[.axis_textcloud_geometry_address]
	mov [.pointer_for_scatterset],rbx

.scatter_set_loop:
	; scatter point struct population
	; TODO loop thru multiple

	mov rdi,98
	call heap_alloc
	test rax,rax
	jz .died
	push rax

	mov ebx, dword [r14+76] ; nPoints
	mov [rax+0],rbx

	mov rbx,[r14+16]
	mov [rax+8],rbx
	mov rbx,[r14+26]
	mov [rax+16],rbx
	mov rbx,[r14+36]
	mov [rax+24],rbx
	mov rbx,[r14+46]
	mov [rax+32],rbx
	mov rbx,[r14+66]
	mov [rax+40],rbx
	mov rbx,[r14+56]
	mov [rax+48],rbx

	mov bx,word [r14+24]
	mov word [rax+56],bx
	mov bx,word [r14+34]
	mov word [rax+58],bx
	mov bx,word [r14+44]
	mov word [rax+60],bx
	mov bx,word [r14+54]
	mov word [rax+62],bx
	mov bx,word [r14+74]
	mov word [rax+64],bx
	mov bx,word [r14+64]
	mov word [rax+66],bx

	mov ebx,dword [r14+80]
	mov dword [rax+68],ebx
	mov bl,byte [r14+85]
	mov byte [rax+72],bl
	mov bl,byte [r14+84]
	mov byte [rax+73],bl

	; offset scatterplot translation
	mov rbx,[r15+40]
	mov [rax+74],rbx
	mov rbx,[r15+48]
	mov [rax+82],rbx
	mov rbx,[r15+56]
	mov [rax+90],rbx
	
	mov rdi,25
	call heap_alloc
	test rax,rax
	jz .died

	xor rbx,rbx
	mov [rax],rbx
	mov [rax+16],rbx
	pop rbx

	mov [rax+8],rbx
	mov rbx,1
	mov byte [rax+24],bl

	mov rbx,[.pointer_for_scatterset]
	mov [rbx],rax

	xor rbx,rbx
	cmp [r14+0],rbx
	jz .scatter_done

	mov r14,[r14+0]
	mov [.pointer_for_scatterset],rax
	jmp .scatter_set_loop

.scatter_done:
; end of scatter points

	mov rax,[.axis_geometry_struct_address]

.died:
	pop rcx
	pop rbx
	pop r14
	pop r15

	ret


.axis_geometry_struct_address:
	dq 0

.axis_textcloud_geometry_address:
	dq 0

.pointer_for_scatterset:
	dq 0

align 8
.byte_fraction:
	dq 0x3F60101010101010 

%endif
