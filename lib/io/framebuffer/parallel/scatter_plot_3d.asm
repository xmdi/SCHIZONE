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
	dq 0.0; plot origin x-position (double) {*+40}
	dq 0.0; plot origin y-position (double) {*+48}
	dq 0.0; plot origin z-position (double) {*+56}
	dq -5.0; x-min (double) {*+64}
	dq 5.0; x-max (double) {*+72}
	dq -6.0; y-min (double) {*+80}
	dq 6.0; y-max (double) {*+88}
	dq -7.0; z-min (double) {*+96}
	dq 7.0; z-max (double) {*+104}
	dq 0; legend x-coordinate {*+112}
	dq 0; legend y-coordinate {*+120}
	dq 0; legend z-coordinate {*+128}
	dd 0x000000; #XXXXXX RGB x-axis color {*+136}
	dd 0x000000; #XXXXXX RGB y-axis color {*+140}
	dd 0x000000; #XXXXXX RGB z-axis color {*+144}
	dd 0x000000; #XXXXXX title/legend RGB font color {*+148}
	db 11; number of major x-ticks {*+152}
	db 5; number of major y-ticks {*+153}
	db 5; number of major z-ticks {*+154}
	db 2; minor subdivisions per x-tick {*+155}
	db 2; minor subdivisions per y-tick {*+156}
	db 2; minor subdivisions per z-tick {*+157}
	db 2; significant digits on x values {*+158}
	db 2; significant digits on y values {*+159}
	db 2; significant digits on z values {*+160}
	db 32; title font size (px) {*+161}
	db 24; axis label font size (px) {*+162}
	db 16; tick & legend label font size (px) {*+163}
	dq 1.0; y-offset for x-tick labels {*+164}
	dq -1.0; x-offset for y-tick labels {*+172}
	dq -1.0; x-offset for z-tick labels {*+180}
	db 2; axis & major tick stroke thickness (px) (0 disables axis) {*+188}
	db 1; minor tick stroke thickness (px) {*+189}
	db 5; x-tick length (px) {*+190}
	db 5; y-tick length (px) {*+191}
	db 5; z-tick length (px) {*+192}
	db 0x1F; flags: {*+193}
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

	mov r15,rdi

	cmp byte [r15+188],0
	je .no_axis

	; create the axis structure	





	; NOTE: tick marks to have their own rendering struct

.no_axis:

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


%endif
