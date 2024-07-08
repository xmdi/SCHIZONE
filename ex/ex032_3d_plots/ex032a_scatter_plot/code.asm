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

%include "lib/io/bitmap/set_line.asm"

%include "lib/io/framebuffer/parallel/framebuffer_3d_render_depth_init.asm"

%include "lib/io/framebuffer/parallel/framebuffer_3d_render_depth_loop.asm"

%include "lib/debug/debug.asm"

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

	; generate scatter plot geometries



	; init rendering
	mov rdi,.perspective_structure
	mov rsi,.axis_geometry
	mov rdx,DRAW_CROSS_CURSOR
	call framebuffer_3d_render_depth_init

.loop: 	; render loop

	call framebuffer_3d_render_depth_loop
	jmp .loop

.perspective_structure:
	dq 10.00 ; lookFrom_x	
	dq 10.00 ; lookFrom_y	
	dq 10.00 ; lookFrom_z	
	dq 0.00 ; lookAt_x	
	dq 0.00 ; lookAt_y	
	dq 0.00 ; lookAt_z	
	dq 0.0 ; upDir_x	
	dq 0.0 ; upDir_y	
	dq 1.0 ; upDir_z	
	dq 0.2	; zoom

.axis_geometry:
	dq .scatter_points_geometry ; next geometry in linked list
	dq .axis_wire_structure ; address of point/edge/face structure
	dq 0xFF000000 ; color (0xARGB)
	db 0b00001001 ; type of structure to render

.axis_wire_structure:
	dq 4 ; number of points (N)
	dq 3 ; number of edges (M)
	dq .axis_points ; starting address of point array (3N elements, 4N if colors)
	dq .axis_edges ; starting address of edge array 
		;	(2M elements if no colors)
		;	(3M elements if colors)
	db 3 ; line thickness


.axis_points:
	dq 0.0,0.0,0.0 ; O
	dq 1.0,0.0,0.0 ; X
	dq 0.0,1.0,0.0 ; Y
	dq 0.0,0.0,1.0 ; Z

.axis_edges:
	dq 0,1,0xFFFF0000 ; X
	dq 0,2,0xFF00FF00 ; Y
	dq 0,3,0xFF0000FF ; Z

.scatter_title:
	db `A sphere`,0

.scatter_xlabel:
	db `x`,0

.scatter_ylabel:
	db `y`,0

.scatter_zlabel:
	db `z`,0

.scatter_plot_structure:
	dq .scatter_title; address of null-terminated title string {*+0}
	dq .scatter_xlabel; address of null-terminated x-label string {*+8}
	dq .scatter_ylabel; address of null-terminated y-label string {*+16}
	dq .scatter_zlabel; address of null-terminated z-label string {*+24}
	dq .scatter_dataset_structure1; address of linked list for datasets {*+32}
	dq 0.0; x-origin (double) {*+40}
	dq 0.0; y-origin (double) {*+48}
	dq 0.0; z-origin (double) {*+56}
	dq -5.0; x-min (double) {*+64}
	dq 5.0; x-max (double) {*+72}
	dq -6.0; y-min (double) {*+80}
	dq 6.0; y-max (double) {*+88}
	dq -7.0; z-min (double) {*+96}
	dq 7.0; z-max (double) {*+104}
	dq 0; legend x-coordinate offset (px) {*+112}
	dq 0; legend y-coordinate offset (px) {*+120}
	dq 0; legend z-coordinate offset (px) {*+128}
	dd 0x000000; #XXXXXX RGB x-axis color {*+136}
	dd 0x000000; #XXXXXX RGB y-axis color {*+140}
	dd 0x000000; #XXXXXX RGB z-axis color {*+144}
	dd 0x000000; #XXXXXX RGB font color {*+148}
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
	db 2; grid major stroke thickness (px) {*+188}
	db 1; grid minor stroke thickness (px) {*+189}
	db 5; x-tick length (px) {*+190}
	db 5; y-tick length (px) {*+191}
	db 5; z-tick length (px) {*+192}
	db 0x1F; flags: {*+193}
		; bit 0 (LSB)	= show title?
		; bit 1		= show x-label?
		; bit 2		= show y-label?
		; bit 3		= show z-label?
		; bit 4		= draw grid?
		; bit 5		= show tick labels?
		; bit 6		= draw legend?

.scatter_dataset_structure1:
	dq 0; .scatter_dataset_structure2; address of next dataset in linked list {*+0}
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
	dq .line0_colors; address of first line color element {*+66}
	dw 0; extra stride between line color elements {*+74}
	dd 101; number of elements {*+76}
	dd 0xFF0000; #XXXXXX RGB marker color {*+80}
	dd 0xFF0000; #XXXXXX RGB line color {*+84}
	db 5; marker size (px) {*+88}
	db 5; line thickness (px) {*+89}
	db 0x03; flags: {*+90}
		; bit 0 (LSB)	= point marker?
		; bit 1		= connecting lines?
		; bit 2		= include in legend?
		; bit 3 	= grab marker size from array?
		; bit 4 	= grab marker color from array?
		; bit 5 	= grab line color from array?


.scatter_data_label_1:
	db `sphere points`,0
.x_coords:
	times 33 dq 1.0
	times 34 dq 2.0
	times 34 dq 3.0
.y_coords:
	times 50 dq 1.0
	times 51 dq 2.0
.z_coords:
	times 20 dq 1.0
	times 20 dq 2.0
	times 20 dq 3.0
	times 20 dq 4.0
	times 21 dq 5.0
.marker0_colors:
	times 101 dd 0xFFFF0000
.marker0_sizes:
	times 101 db 5
.line0_colors:
	times 101 dd 0xFF0000FF

.scatter_points_geometry:
	dq 0 ; next geometry in linked list
	dq .scatter_points_structure ; address of point/edge/face structure
	dq 0x1FF000000 ; color (0xARGB) NOTE: UNUSED!
	db 0b00000001 ; type of structure to render

.scatter_points_structure:
	dq 4 ; number of points (N)
	dq .scatter_points_xyz ; pointer to (x,y,z) point array (24N bytes)
	dq .scatter_marker_colors ; pointer (4N bytes)
	dq .scatter_marker_types ; pointer to render type (N bytes)
				; (1=O,2=X,3=[],4=tri)
	dq .scatter_marker_sizes ; pointer (N bytes)
	dd 0 ; global marker color if NULL pointer set above
	db 0 ; point render type (1=O,2=X,3=[],4=tri) if NULL pointer set above
	db 0 ; characteristic size of each point if NULL pointer set above

.scatter_points_xyz:
	dq 0.5,-0.5,0.0
	dq -0.5,0.5,2.0
	dq -0.5,-0.5,0.0
	dq 0.5,-0.5,1.0

.scatter_marker_colors:
	dd 0xFFFF0000
	dd 0xFF00FF00
	dd 0xFF0000FF
	dd 0xFFFFFF00

.scatter_marker_types:
	db 4,2,3,3

.scatter_marker_sizes:
	db 15,10,5,3

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)

