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

	mov rdi,.perspective_structure
	mov rsi,.cross_geometry
	mov rdx,DRAW_CROSS_CURSOR
	call framebuffer_3d_render_depth_init

.loop:

	[map all myfile.map]

	call framebuffer_3d_render_depth_loop
	jmp .loop

.perspective_structure:
	dq 0.00 ; lookFrom_x	
	dq 10.00 ; lookFrom_y	
	dq 2.00 ; lookFrom_z	
	dq 0.00 ; lookAt_x	
	dq 0.00 ; lookAt_y	
	dq 2.00 ; lookAt_z	
	dq 0.0 ; upDir_x	
	dq 0.0 ; upDir_y	
	dq 1.0 ; upDir_z	
	dq 0.2	; zoom

.cross_geometry:
	dq .cube_wire_geometry ; next geometry in linked list
	dq .cross_structure ; address of point/edge/face structure
	dq 0x1000000FF ; color (0xARGB)
	db 0b00000101 ; type of structure to render

.cross_structure:
	dq 24 ; number of points (N)
	dq 36 ; number of faces (M)
	dq .cross_points ; starting address of point array (3N elements, 4N if colors)
	dq .cross_faces ; starting address of face array 
		;	(3M elements if no colors)
		;	(4M elements if colors)

.cube_geometry:
	dq .cube_wire_geometry ; next geometry in linked list
	dq .cube_structure ; address of point/edge/face structure
	dq 0x1000000FF ; color (0xARGB)
	db 0b00000101 ; type of structure to render

.cube_structure:
	dq 8 ; number of points (N)
	dq 12 ; number of faces (M)
	dq .cube_points ; starting address of point array (3N elements, 4N if colors)
	dq .cube_faces ; starting address of face array 
		;	(3M elements if no colors)
		;	(4M elements if colors)

.cube_wire_geometry:
	dq .cube_point_geometry ; next geometry in linked list
	dq .cube_wire_structure ; address of point/edge/face structure
	dq 0xFF00FFFF ; color (0xARGB)
	db 0b00001010 ; type of structure to render

.cube_wire_structure:
	dq 8 ; number of points (N)
	dq 12 ; number of edges (M)
	dq .cube_points2 ; starting address of point array (3N elements, 4N if colors)
	dq .cube_edges ; starting address of edge array 
		;	(2M elements if no colors)
		;	(3M elements if colors)
	db 10 ; line thickness

.cube_point_geometry:
	dq 0 ; next geometry in linked list
	dq .cube_point_structure ; address of point/edge/face structure
	dq 0x1FFFF0000 ; color (0xARGB)
	db 0b00000001 ; type of structure to render

.cube_point_structure:
	dq 8 ; number of points (N)
	dq .cube_points ; starting address of point array (3N elements)
	dq 1 ; point render type (1=O,2=X,3=[],4=tri)
	dq 15 ; characteristic size of each point

.cross_points:
	; base of vertical beam
	dq 0.5,0.5,0.0
	dq -0.5,0.5,0.0
	dq -0.5,-0.5,0.0
	dq 0.5,-0.5,0.0

	; bottom of cross beam
	dq 0.5,0.5,2.0
	dq -0.5,0.5,2.0
	dq -0.5,-0.5,2.0
	dq 0.5,-0.5,2.0

	; top of cross beam
	dq 0.5,0.5,3.0
	dq -0.5,0.5,3.0
	dq -0.5,-0.5,3.0
	dq 0.5,-0.5,3.0

	; top of vertical beam
	dq 0.5,0.5,4.0
	dq -0.5,0.5,4.0
	dq -0.5,-0.5,4.0
	dq 0.5,-0.5,4.0

	; left side of cross beam
	dq 1.5,0.5,2.0
	dq 1.5,-0.5,2.0
	dq 1.5,-0.5,3.0
	dq 1.5,0.5,3.0

	; right side of cross beam
	dq -1.5,0.5,2.0
	dq -1.5,-0.5,2.0
	dq -1.5,-0.5,3.0
	dq -1.5,0.5,3.0

.cross_faces:
	dq 0,2,1,0xFFFF0000 ; bottom
	dq 0,3,2,0xFFFF0000 ; bottom

	dq 17,7,16,0xFFFF0000 ; bottom right
	dq 16,7,4,0xFFFF0000 ; bottom right

	dq 5,21,20,0xFFFF0000 ; bottom left
	dq 5,6,21,0xFFFF0000 ; bottom left
	
	dq 13,14,12,0xFF0000FF ; top
	dq 14,15,12,0xFF0000FF ; top

	dq 11,18,19,0xFF0000FF ; top right
	dq 11,19,8,0xFF0000FF ; top right

	dq 9,23,22,0xFF0000FF ; top left
	dq 9,22,10,0xFF0000FF ; top left

	dq 0,13,12,0xFF00FF00 ; front
	dq 0,1,13,0xFF00FF00 ; front

	dq 5,23,9,0xFF00FF00 ; front right	
	dq 5,20,23,0xFF00FF00 ; front right	

	dq 4,8,19,0xFF00FF00 ; front left	
	dq 4,19,16,0xFF00FF00 ; front left	
	
	dq 3,14,2,0xFFFFFFFF ; back
	dq 3,15,14,0xFFFFFFFF ; back

	dq 7,18,11,0xFFFFFFFF ; back left
	dq 7,17,18,0xFFFFFFFF ; back left
	
	dq 6,22,21,0xFFFFFFFF ; back right
	dq 6,10,22,0xFFFFFFFF ; back right
	
	dq 16,18,17,0xFFFF00FF ; left
	dq 16,19,18,0xFFFF00FF ; left
	
	dq 8,12,15,0xFFFF00FF ; top left
	dq 8,15,11,0xFFFF00FF ; top left
	
	dq 0,7,3,0xFFFF00FF ; bottom left
	dq 0,4,7,0xFFFF00FF ; bottom left
	
	dq 20,22,23,0xFFFFFF00 ; right
	dq 20,21,22,0xFFFFFF00 ; right
	
	dq 9,14,13,0xFFFFFF00 ; top right
	dq 9,10,14,0xFFFFFF00 ; top right
	
	dq 2,6,5,0xFFFFFF00 ; bottom right
	dq 2,5,1,0xFFFFFF00 ; bottom right

.cube_points:
	; base
	dq 0.5,-4.5,0.0
	dq -0.5,-4.5,0.0
	dq -0.5,-5.5,0.0
	dq 0.5,-5.5,0.0

	; top
	dq 0.5,-4.5,1.0
	dq -0.5,-4.5,1.0
	dq -0.5,-5.5,1.0
	dq 0.5,-5.5,1.0

.cube_points2:
	; base
	dq 0.5,-4.5,0.0,0xFF0000FF
	dq -0.5,-4.5,0.0,0xFF00FF00
	dq -0.5,-5.5,0.0,0xFFFF0000
	dq 0.5,-5.5,0.0,0xFFFF00FF

	; top
	dq 0.5,-4.5,1.0,0xFF0000FF
	dq -0.5,-4.5,1.0,0xFF00FF00
	dq -0.5,-5.5,1.0,0xFFFF0000
	dq 0.5,-5.5,1.0,0xFFFF00FF

.cube_faces:
	dq 0,2,1,0xFFFF0000 ; bottom
	dq 0,3,2,0xFFFF0000 ; bottom
	
	dq 5,6,4,0xFF0000FF ; top
	dq 6,7,4,0xFF0000FF ; top
	
	dq 0,4,3,0xFFFF00FF ; left
	dq 7,3,4,0xFFFF00FF ; left

	dq 1,2,5,0xFFFFFF00 ; right
	dq 6,5,2,0xFFFFFF00 ; right
	
	dq 0,1,4,0xFF00FF00 ; front
	dq 4,1,5,0xFF00FF00 ; front

	dq 2,3,6,0xFFFFFFFF ; back
	dq 6,3,7,0xFFFFFFFF ; bac

.cube_edges:
	dq 0,1,0xFFFF0000 ; bottom
	dq 1,2,0xFFFF0000 ; bottom
	dq 2,3,0xFFFF0000 ; bottom
	dq 3,0,0xFFFF0000 ; bottom
	
	dq 4,5,0xFFFF0000 ; top
	dq 5,6,0xFFFF0000 ; top
	dq 6,7,0xFFFF0000 ; top
	dq 7,4,0xFFFF0000 ; top
	
	dq 0,4,0xFFFF0000 ; sides
	dq 1,5,0xFFFF0000 ; sides
	dq 2,6,0xFFFF0000 ; sides
	dq 3,7,0xFFFF0000 ; sides
		
	[map all myfile.map]

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)

