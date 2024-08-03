;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define LOAD_ADDRESS 0x00020000 ; pretty much any number >0 works
%define CODE_SIZE END-(LOAD_ADDRESS+0x78) ; everything beyond HEADER is code
%define PRINT_BUFFER_SIZE 4096
%define HEAP_SIZE 0x2000000

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

%include "lib/io/bitmap/SCHIZOFONT.asm"

%include "lib/io/bitmap/set_line.asm"

%include "lib/math/expressions/trig/sine.asm"

%include "lib/io/framebuffer/parallel/framebuffer_3d_render_depth_init.asm"

%include "lib/io/framebuffer/parallel/framebuffer_3d_render_depth_loop.asm"

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

	call heap_init
	
	; generate scatterplot data
	
	N equ 101 ; number of discrete datapoints along the x and y axes
	mov rdi,N*N*8

	; array for x-coords (used for both datasets)
	call heap_alloc
	mov [.scatter_dataset_structure1+16],rax
	mov [.scatter_dataset_structure2+16],rax
	mov r8,rax
	mov r12,rax

	; array for y-coords (used for both datasets)
	call heap_alloc
	mov [.scatter_dataset_structure1+26],rax
	mov [.scatter_dataset_structure2+26],rax
	mov r9,rax
	mov r13,rax

	; array for z-coords1 (dataset 1 z)
	call heap_alloc
	mov [.scatter_dataset_structure1+36],rax
	mov r14,rax

	; array for z-coords2 (dataset 2 z)
	call heap_alloc
	mov [.scatter_dataset_structure2+36],rax
	mov r15,rax

	mov r11,N*N

	mov rax,-10
	mov rbx,10
	mov rcx,N
	dec rcx
	cvtsi2sd xmm0,rax ; min
	cvtsi2sd xmm1,rbx ; max -> step size
	cvtsi2sd xmm2,rcx ; num steps
	subsd xmm1,xmm0
	divsd xmm1,xmm2
	inc rcx

.x_loop_outer:
	movsd xmm3,xmm0 ; tracking x value
	mov rdx,N

.x_loop_inner:
	movsd [r8],xmm3
	add r8,8
	addsd xmm3,xmm1

	dec rdx
	jnz .x_loop_inner

	dec rcx
	jnz .x_loop_outer


	movsd xmm3,xmm0 ; tracking y value
	mov rcx,N

.y_loop_outer:
	mov rdx,N

.y_loop_inner:
	movsd [r9],xmm3
	add r9,8
	dec rdx
	jnz .y_loop_inner

	addsd xmm3,xmm1
	dec rcx
	jnz .y_loop_outer

.z_loop:

	movsd xmm0,[r12]
	mulsd xmm0,[r13]
	movsd xmm1,[.tolerance]
	call sine
	
	movsd xmm1,xmm0
	addsd xmm0,[.five]
	subsd xmm1,[.five]
	
	movsd [r14],xmm0
	movsd [r15],xmm1

	add r12,8
	add r13,8
	add r14,8
	add r15,8
	dec r11
	jnz .z_loop


	mov rdi,.scatter_plot_structure
	call scatter_plot_3d

	; init rendering
	mov rdi,.perspective_structure
	mov rsi,rax
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
	dq 0.08 ; zoom

.scatter_title:
	db `z=sin(xy)+/-5`,0

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
	dq 0.0; title x-coordinate {*+136}
	dq 0.0; title y-coordinate {*+144}
	dq 12.0; title z-coordinate {*+152}
	dd 0xFFFF0000; #XXXXXX RGB x-axis color {*+160}
	dd 0xFF00FF00; #XXXXXX RGB y-axis color {*+164}
	dd 0xFF0000FF; #XXXXXX RGB z-axis color {*+168}
	dd 0xFFFFFFFF; #XXXXXX title RGB font color {*+172}
	db 5; number of major x-ticks {*+176}
	db 5; number of major y-ticks {*+177}
	db 5; number of major z-ticks {*+178}
	db 2; minor subdivisions per x-tick {*+179}
	db 2; minor subdivisions per y-tick {*+180}
	db 2; minor subdivisions per z-tick {*+181}
	db 3; significant digits on x values {*+182}
	db 3; significant digits on y values {*+183}
	db 3; significant digits on z values {*+184}
	db 4; title font size (px) {*+185}
	db 3; axis label font size (px) {*+186}
	db 2; tick label font size (px) {*+187}
	dq 1.0; y-offset for x-tick labels {*+188}
	dq 0.5; z-offset for y-tick labels {*+196}
	dq -1.0; x-offset for z-tick labels {*+204}
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
	dq .scatter_dataset_structure2; address of next dataset in linked list {*+0}
	dq 0; address of null-terminated label string, currently unused {*+8}
	dq 0; address of first x-coordinate {*+16}
	dw 0; extra stride between x-coord elements {*+24}
	dq 0; address of first y-coordinate {*+26}
	dw 0; extra stride between y-coord elements {*+34}	
	dq 0; address of first z-coordinate {*+36}
	dw 0; extra stride between z-coord elements {*+44}
	dq 0; address of first marker color element {*+46}
	dw 0; extra stride between marker color elements {*+54}
	dq 0; address of first marker size element {*+56}
	dw 0; extra stride between marker size elements {*+64}
	dq 0; address of first marker type element {*+66}
	dw 0; extra stride between marker type elements {*+74}
	dd N*N; number of elements {*+76}
	dd 0xFFFF00; default #XXXXXX RGB marker color {*+80}
	db 2; default marker size (px) {*+84}
	db 1; default marker type (1-4) {*+85}
	db 0x00; flags: currently unused {*+86}

.scatter_dataset_structure2:
	dq 0; address of next dataset in linked list {*+0}
	dq 0; address of null-terminated label string, currently unused {*+8}
	dq 0; address of first x-coordinate {*+16}
	dw 0; extra stride between x-coord elements {*+24}
	dq 0; address of first y-coordinate {*+26}
	dw 0; extra stride between y-coord elements {*+34}	
	dq 0; address of first z-coordinate {*+36}
	dw 0; extra stride between z-coord elements {*+44}
	dq 0; address of first marker color element {*+46}
	dw 0; extra stride between marker color elements {*+54}
	dq 0; address of first marker size element {*+56}
	dw 0; extra stride between marker size elements {*+64}
	dq 0; address of first marker type element {*+66}
	dw 0; extra stride between marker type elements {*+74}
	dd N*N; number of elements {*+76}
	dd 0x00FFFF; default #XXXXXX RGB marker color {*+80}
	db 2; default marker size (px) {*+84}
	db 2; default marker type (1-4) {*+85}
	db 0x00; flags: currently unused {*+86}

.tolerance:
	dq 0.0001

.five:
	dq 5.0

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)

