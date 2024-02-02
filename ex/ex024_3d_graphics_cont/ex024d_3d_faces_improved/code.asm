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

%include "lib/io/framebuffer/framebuffer_3d_render_init.asm"

%include "lib/io/framebuffer/framebuffer_3d_render_loop.asm"

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
	mov rsi,.faces_geometry
	mov rdx,DRAW_CROSS_CURSOR
	call framebuffer_3d_render_init

.loop:
	call framebuffer_3d_render_loop
	jmp .loop

.perspective_structure:
	dq 3.00 ; lookFrom_x	
	dq 2.00 ; lookFrom_y	
	dq 2.00 ; lookFrom_z	
	dq 0.00 ; lookAt_x	
	dq 0.00 ; lookAt_y	
	dq 2.00 ; lookAt_z	
	dq 0.0 ; upDir_x	
	dq 0.0 ; upDir_y	
	dq 1.0 ; upDir_z	
	dq 0.3	; zoom

.faces_geometry:
	dq 0 ; next geometry in linked list
	dq .shell_list_structure ; address of point/edge/face structure
	dq 0x100000000 ; color (0xARGB)
	db 0b00000101 ; type of structure to render

.shell_list_structure:
	dq 4 ; number of structures
	dq .faces_top_structure ; address of shell body structure
	dq 0.0, 0.0, 3.5 ; centroid of shell body structure
	dq .faces_bottom_structure ; address of shell body structure
	dq 0.0, 0.0, 1.0 ; centroid of shell body structure
	dq .faces_right_structure ; address of shell body structure
	dq -1.0, 0.0, 2.5 ; centroid of shell body structure
	dq .faces_left_structure ; address of shell body structure
	dq 1.0, 0.0, 2.5 ; centroid of shell body structure

.faces_top_structure:
	dq 24 ; number of points (N)
	dq 10 ; number of faces (M)
	dq .points ; starting address of point array (3N elements)
	dq .faces_top ; starting address of face array 
		;	(3M elements if no colors)
		;	(4M elements if colors)

.faces_bottom_structure:
	dq 24 ; number of points (N)
	dq 10 ; number of faces (M)
	dq .points ; starting address of point array (3N elements)
	dq .faces_bottom ; starting address of face array 
		;	(3M elements if no colors)
		;	(4M elements if colors)

.faces_right_structure:
	dq 24 ; number of points (N)
	dq 10 ; number of faces (M)
	dq .points ; starting address of point array (3N elements)
	dq .faces_right ; starting address of face array 
		;	(3M elements if no colors)
		;	(4M elements if colors)

.faces_left_structure:
	dq 24 ; number of points (N)
	dq 10 ; number of faces (M)
	dq .points ; starting address of point array (3N elements)
	dq .faces_left ; starting address of face array 
		;	(3M elements if no colors)
		;	(4M elements if colors)

.points:
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

.faces_top:
	
	dq 13,12,14,0x1FF0000FF ; top
	dq 14,12,15,0x1FF0000FF ; top

	dq 8,15,12,0x1FFFF00FF ; top left
	dq 8,11,15,0x1FFFF00FF ; top left
	
	dq 9,13,14,0x1FFFFFF00 ; top right
	dq 9,14,10,0x1FFFFFF00 ; top right
	
	dq 9,8,12,0x1FF00FF00 ; top front
	dq 9,12,13,0x1FF00FF00 ; top front

	dq 11,10,15,0x1FFFFFFFF ; top back
	dq 10,14,15,0x1FFFFFFFF ; top back

.faces_bottom:

	dq 0,1,2,0x1FFFF0000 ; bottom
	dq 0,2,3,0x1FFFF0000 ; bottom

	dq 0,3,7,0x1FFFF00FF ; bottom left
	dq 0,7,4,0x1FFFF00FF ; bottom left
	
	dq 2,5,6,0x1FFFFFF00 ; bottom right
	dq 2,1,5,0x1FFFFFF00 ; bottom right

	dq 0,8,9,0x1FF00FF00 ; top front
	dq 0,9,1,0x1FF00FF00 ; top front

	dq 3,2,10,0x1FFFFFFFF ; top back
	dq 3,10,11,0x1FFFFFFFF ; top back

.faces_right:

	dq 5,20,21,0x1FFFF0000 ; bottom left
	dq 5,21,6,0x1FFFF0000 ; bottom left
	
	dq 9,22,23,0x1FF0000FF ; top left
	dq 9,10,22,0x1FF0000FF ; top left

	dq 5,9,23,0x1FF00FF00 ; front right	
	dq 5,23,20,0x1FF00FF00 ; front right	

	dq 6,21,22,0x1FFFFFFFF ; back right
	dq 6,22,10,0x1FFFFFFFF ; back right

	dq 20,23,22,0x1FFFFFF00 ; right
	dq 20,22,21,0x1FFFFFF00 ; right


.faces_left:

	dq 17,16,7,0x1FFFF0000 ; bottom right
	dq 16,4,7,0x1FFFF0000 ; bottom right

	dq 11,19,18,0x1FF0000FF ; top right
	dq 11,8,19,0x1FF0000FF ; top right

	dq 4,19,8,0x1FF00FF00 ; front left	
	dq 4,16,19,0x1FF00FF00 ; front left	
	
	dq 7,11,18,0x1FFFFFFFF ; back left
	dq 7,18,17,0x1FFFFFFFF ; back left
	
	dq 16,17,18,0x1FFFF00FF ; left
	dq 16,18,19,0x1FFFF00FF ; left

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)

