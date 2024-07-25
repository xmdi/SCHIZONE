;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define LOAD_ADDRESS 0x00020000 ; pretty much any number >0 works
%define CODE_SIZE END-(LOAD_ADDRESS+0x78) ; everything beyond HEADER is code
%define PRINT_BUFFER_SIZE 4096
%define HEAP_SIZE 0x8000000

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

%include "lib/debug/debug.asm"

%include "lib/io/bitmap/SCHIZOFONT.asm"

%include "lib/io/bitmap/set_line.asm"

%include "lib/io/framebuffer/parallel/framebuffer_3d_render_depth_init.asm"

%include "lib/io/framebuffer/parallel/framebuffer_3d_render_depth_loop.asm"

%include "lib/math/rand/rand_float_array.asm"

%include "lib/math/rand/rand_int_array.asm"

%include "lib/math/rand/rand_int_nbytes_array.asm"

%include "lib/io/print_memory.asm"

%include "lib/io/print_array_float.asm"

%include "lib/io/print_array_int.asm"

%include "lib/io/framebuffer/parallel/scatter_plot_3d.asm"


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
	mov rax,-10
	cvtsi2sd xmm0,rax
	mov rax,10
	cvtsi2sd xmm1,rax	
	mov rdx,101
	xor rsi,rsi
	mov rdi,.x_coords
	call rand_float_array
	mov rdi,.y_coords
	call rand_float_array
	mov rdi,.z_coords
	call rand_float_array
	mov rdi,.marker0_types
	mov rcx,1
	mov r8,4
	mov r9,1
	call rand_int_nbytes_array

	mov rdi,.marker0_sizes
	mov rcx,1
	mov r8,10
	call rand_int_nbytes_array
	mov rdi,.marker0_colors
	mov rcx,0
	mov r8,0xFFFFFF
	mov r9,4
	call rand_int_nbytes_array

	call heap_init

	mov rdi,.scatter_plot_structure
	call scatter_plot_3d

	mov [.scatter_points_geometry],rax ; reactivate this

	; init rendering
	mov rdi,.perspective_structure
	mov rsi,.scatter_points_geometry
	;mov rsi,.text_1_geometry
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
	db `Random Scatterplot`,0

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
	dq .scatter_dataset_structure1; addr of linked list for datasets {*+32}
	dq 0.0; plot origin x translation (double) {*+40}
	dq 0.0; plot origin y translation (double) {*+48}
	dq 0.0; plot origin z translation (double) {*+56}
	dq 0.0; origin x-coord (double) {*+64}
	dq 0.0; origin y-coord (double) {*+72}
	dq 0.0; origin z_coord (double) {*+80}
	dq -10.0; x-min (double) {*+88}
	dq 10.0; x-max (double) {*+96}
	dq -10.0; y-min (double) {*+104}
	dq 10.0; y-max (double) {*+112}
	dq -10.0; z-min (double) {*+120}
	dq 10.0; z-max (double) {*+128}
	dq 0.0; legend x-coordinate {*+136}
	dq -5.0; legend y-coordinate {*+144}
	dq 12.0; legend z-coordinate {*+152}
	dd 0xFFFF0000; #XXXXXX RGB x-axis color {*+160}
	dd 0xFF00FF00; #XXXXXX RGB y-axis color {*+164}
	dd 0xFF0000FF; #XXXXXX RGB z-axis color {*+168}
	dd 0xFFFFFFFF; #XXXXXX title/legend RGB font color {*+172}
	db 11; number of major x-ticks {*+176}
	db 5; number of major y-ticks {*+177}
	db 6; number of major z-ticks {*+178}
	db 2; minor subdivisions per x-tick {*+179}
	db 2; minor subdivisions per y-tick {*+180}
	db 2; minor subdivisions per z-tick {*+181}
	db 3; significant digits on x values {*+182}
	db 3; significant digits on y values {*+183}
	db 3; significant digits on z values {*+184}
	db 4; title font size (px) {*+185}
	db 3; axis label font size (px) {*+186}
	db 2; tick & legend label font size (px) {*+187}
	dq 0.5; y-offset for x-tick labels {*+188}
	dq 0.5; z-offset for y-tick labels {*+196}
	dq -0.5; x-offset for z-tick labels {*+204}
	db 2; axis & major tick stroke thickness (px) (0 disables axis) {*+212}
	db 5; x-tick fraction (/255) {*+213}
	db 5; y-tick fraction (/255) {*+214}
	db 5; z-tick fraction (/255) {*+215}
	db 0xFF; flags: {*+216}
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
	db 0x01; flags: {*+86}
		; bit 0 (LSB)	= include in legend?

.scatter_data_label_1:
	db `sphere points`,0
.x_coords:
	times 101 dq 0.0
.y_coords:
	times 101 dq 0.0
.z_coords:
	times 101 dq 0.0
.marker0_colors:
	times 101 dd 0
.marker0_sizes:
	times 101 db 0
.marker0_types:
	times 101 db 0

	; container for pointcloud rendering struct
.scatter_points_geometry:
	dq 0 ; next geometry in linked list
	dq .scatter_points_structure ; address of point/edge/face structure
	dq 0x1FF000000 ; color (0xARGB) NOTE: UNUSED!
	db 0b00000001 ; type of structure to render

	; pointcloud rendering struct
.scatter_points_structure:
	dq 101 ; number of points (N)
	dq .x_coords ; pointer to (x) point array (8N bytes)
	dq .y_coords ; pointer to (y) point array (8N bytes)
	dq .z_coords ; pointer to (z) point array (8N bytes)
	dq .marker0_colors ; pointer (4N bytes)
	dq .marker0_types ; pointer to render type (N bytes)
				; (1=O,2=X,3=[],4=tri)
	dq .marker0_sizes ; pointer (N bytes)
	dw 0 ;
	dw 0 ;
	dw 0 ;
	dw 0 ;
	dw 0 ;
	dw 0 ;
	dd 0 ; global marker color if NULL pointer set above
	db 0 ; point render type (1=O,2=X,3=[],4=tri) if NULL pointer set above
	db 0 ; characteristic size of each point if NULL pointer set above

%if 0
.text_1_geometry:
	dq .scatter_points_geometry ; next geometry in linked list
	dq .text_1_structure ; address of point/edge/face structure
	dq 0x1FFFF0000 ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.text_1_structure:
	dq .text_1_position ; address of 24-byte (x,y,z) position
	dq .text_1 ; address of null-terminated string
	dq SCHIZOFONT ; address of font definition
	dq 4 ; font-size (scaling of 8px)

.text_1_position:
	dq 10.0,10.0,10.0

.text_1:
	db `Jeffrey Epstein`,0
%endif

%if 0
.text_1_geometry:
	dq .scatter_points_geometry ; next geometry in linked list
	dq .text_1_structure ; address of point/edge/face structure
	dq 0x1FFFF0000 ; color (unused for textclouds)
	db 0b00000011 ; type of structure to render

.text_1_structure:
	dq .text_1_array ; address of 24-byte (x,y,z,char*,ARGB) 
	dq 2 ; number of textboxes
	dq SCHIZOFONT ; address of font definition
	dq 4 ; font-size (scaling of 8px)

.text_1_array:
	dq 10.0,10.0,10.0,.text_1
       	dd 0xFFFF0000
	dq 10.0,-10.0,10.0,.text_2
       	dd 0xFF0000FF

.text_1:
	db `Jeffrey Epstein`,0
	
.text_2:
	db `George W. Bush`,0

%endif

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)

