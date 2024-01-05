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

%include "lib/io/bitmap/set_line.asm"
; void set_line(void* {rdi}, int {esi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});

%include "lib/sys/exit.asm"

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
	mov rsi,.north_tower_geometry
	mov rdx,DRAW_CROSS_CURSOR
	call framebuffer_3d_render_init

.loop:
	call framebuffer_3d_render_loop
	jmp .loop

.perspective_structure:
	dq 1.00 ; lookFrom_x	
	dq 2.00 ; lookFrom_y	
	dq 2.00 ; lookFrom_z	
	dq 0.00 ; lookAt_x	
	dq 0.00 ; lookAt_y	
	dq 2.00 ; lookAt_z	
	dq 0.0 ; upDir_x	
	dq 0.0 ; upDir_y	
	dq 1.0 ; upDir_z	
	dq 0.3	; zoom

.north_tower_geometry:
	dq .south_tower_geometry ; next geometry in linked list
	dq .north_tower_structure ; address of point/edge/face structure
	dq 0x1FFAAAAAA ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.south_tower_geometry:
	dq .third_tower_geometry ; next geometry in linked list
	dq .south_tower_structure ; address of point/edge/face structure
	dq 0x1FFAAAAAA ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.third_tower_geometry:
	dq .explosive_1_geometry;.plane_1_geometry ; next geometry in linked list
	dq .third_tower_structure ; address of point/edge/face structure
	dq 0x1FFAAAAAA ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.explosive_1_geometry:
	dq .explosive_2_geometry ; next geometry in linked list
	dq .explosive_1_structure ; address of point/edge/face structure
	dq 0x1FFFF0000 ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.explosive_2_geometry:
	dq .explosive_3_geometry ; next geometry in linked list
	dq .explosive_2_structure ; address of point/edge/face structure
	dq 0x1FFFF0000 ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.explosive_3_geometry:
	dq .explosive_4_geometry ; next geometry in linked list
	dq .explosive_3_structure ; address of point/edge/face structure
	dq 0x1FFFF0000 ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.explosive_4_geometry:
	dq .explosive_5_geometry ; next geometry in linked list
	dq .explosive_4_structure ; address of point/edge/face structure
	dq 0x1FFFF0000 ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.explosive_5_geometry:
	dq .explosive_6_geometry ; next geometry in linked list
	dq .explosive_5_structure ; address of point/edge/face structure
	dq 0x1FFFF0000 ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.explosive_6_geometry:
	dq .explosive_7_geometry ; next geometry in linked list
	dq .explosive_6_structure ; address of point/edge/face structure
	dq 0x1FFFF0000 ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.explosive_7_geometry:
	dq .explosive_8_geometry ; next geometry in linked list
	dq .explosive_7_structure ; address of point/edge/face structure
	dq 0x1FFFF0000 ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.explosive_8_geometry:
	dq .explosive_9_geometry ; next geometry in linked list
	dq .explosive_8_structure ; address of point/edge/face structure
	dq 0x1FFFF0000 ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.explosive_9_geometry:
	dq .explosive_10_geometry ; next geometry in linked list
	dq .explosive_9_structure ; address of point/edge/face structure
	dq 0x1FFFF0000 ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.explosive_10_geometry:
	dq .plane_1_geometry ; next geometry in linked list
	dq .explosive_10_structure ; address of point/edge/face structure
	dq 0x1FFFF0000 ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.plane_1_geometry:
	dq .plane_2_geometry ; next geometry in linked list
	dq .plane_1_structure ; address of point/edge/face structure
	dq 0x1FFFFFFFF ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.plane_2_geometry:
	dq 0 ; next geometry in linked list
	dq .plane_2_structure ; address of point/edge/face structure
	dq 0x1FFFFFFFF ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.north_tower_structure:
	dq 8 ; number of points (N)
	dq 12 ; number of edges (M)
	dq .north_tower_points ; starting address of point array (3N elements)
	dq .tower_edges ; starting address of edge array (2M elements)

.south_tower_structure:
	dq 8 ; number of points (N)
	dq 12 ; number of edges (M)
	dq .south_tower_points ; starting address of point array (3N elements)
	dq .tower_edges ; starting address of edge array (2M elements)

.third_tower_structure:
	dq 8 ; number of points (N)
	dq 12 ; number of edges (M)
	dq .third_tower_points ; starting address of point array (3N elements)
	dq .tower_edges ; starting address of edge array (2M elements)

.explosive_1_structure:
	dq 8 ; number of points (N)
	dq 12 ; number of edges (M)
	dq .explosive_1_points ; starting address of point array (3N elements)
	dq .tower_edges ; starting address of edge array (2M elements)

.explosive_2_structure:
	dq 8 ; number of points (N)
	dq 12 ; number of edges (M)
	dq .explosive_2_points ; starting address of point array (3N elements)
	dq .tower_edges ; starting address of edge array (2M elements)

.explosive_3_structure:
	dq 8 ; number of points (N)
	dq 12 ; number of edges (M)
	dq .explosive_3_points ; starting address of point array (3N elements)
	dq .tower_edges ; starting address of edge array (2M elements)

.explosive_4_structure:
	dq 8 ; number of points (N)
	dq 12 ; number of edges (M)
	dq .explosive_4_points ; starting address of point array (3N elements)
	dq .tower_edges ; starting address of edge array (2M elements)

.explosive_5_structure:
	dq 8 ; number of points (N)
	dq 12 ; number of edges (M)
	dq .explosive_5_points ; starting address of point array (3N elements)
	dq .tower_edges ; starting address of edge array (2M elements)

.explosive_6_structure:
	dq 8 ; number of points (N)
	dq 12 ; number of edges (M)
	dq .explosive_6_points ; starting address of point array (3N elements)
	dq .tower_edges ; starting address of edge array (2M elements)

.explosive_7_structure:
	dq 8 ; number of points (N)
	dq 12 ; number of edges (M)
	dq .explosive_7_points ; starting address of point array (3N elements)
	dq .tower_edges ; starting address of edge array (2M elements)

.explosive_8_structure:
	dq 8 ; number of points (N)
	dq 12 ; number of edges (M)
	dq .explosive_8_points ; starting address of point array (3N elements)
	dq .tower_edges ; starting address of edge array (2M elements)

.explosive_9_structure:
	dq 8 ; number of points (N)
	dq 12 ; number of edges (M)
	dq .explosive_9_points ; starting address of point array (3N elements)
	dq .tower_edges ; starting address of edge array (2M elements)

.explosive_10_structure:
	dq 8 ; number of points (N)
	dq 12 ; number of edges (M)
	dq .explosive_10_points ; starting address of point array (3N elements)
	dq .tower_edges ; starting address of edge array (2M elements)

.plane_1_structure:
	dq 56 ; number of points (N)
	dq 91 ; number of edges (M)
	dq .plane_1_points ; starting address of point array (3N elements)
	dq .plane_edges ; starting address of edge array (2M elements)

.plane_2_structure:
	dq 56 ; number of points (N)
	dq 91 ; number of edges (M)
	dq .plane_2_points ; starting address of point array (3N elements)
	dq .plane_edges ; starting address of edge array (2M elements)

.north_tower_points:
	; base
	dq 1.5,0.5,0.0
	dq 0.5,0.5,0.0
	dq 0.5,-0.5,0.0
	dq 1.5,-0.5,0.0
	; top
	dq 1.5,0.5,4.0
	dq 0.5,0.5,4.0
	dq 0.5,-0.5,4.0
	dq 1.5,-0.5,4.0

.south_tower_points:
	; base
	dq -1.5,0.5,0.0
	dq -0.5,0.5,0.0
	dq -0.5,-0.5,0.0
	dq -1.5,-0.5,0.0
	; top
	dq -1.5,0.5,4.0
	dq -0.5,0.5,4.0
	dq -0.5,-0.5,4.0
	dq -1.5,-0.5,4.0

.third_tower_points:
	; base
	dq -3.5,0.5,0.0
	dq -2.5,0.5,0.0
	dq -2.5,-0.5,0.0
	dq -3.5,-0.5,0.0
	; top
	dq -3.5,0.5,2.0
	dq -2.5,0.5,2.0
	dq -2.5,-0.5,2.0
	dq -3.5,-0.5,2.0

.tower_edges: ; valid for both north and south towers
	;base
	dq 0,1
	dq 1,2
	dq 2,3
	dq 3,0
	;top
	dq 4,5
	dq 5,6
	dq 6,7
	dq 7,4
	;sides
	dq 0,4
	dq 1,5
	dq 2,6
	dq 3,7

.plane_1_points:
	dq 1.0,2.9,3.0 ; pointy nose
	dq 1.025,3.0,3.075 ; front 1
	dq 0.975,3.0,3.075 ; front 2
	dq 0.925,3.0,3.025 ; front 3
	dq 0.925,3.0,2.975 ; front 4
	dq 0.975,3.0,2.925 ; front 5
	dq 1.025,3.0,2.925 ; front 6
	dq 1.075,3.0,2.975 ; front 7
	dq 1.075,3.0,3.025 ; front 8
	dq 1.025,4.0,3.075 ; back 1 ****
	dq 0.975,4.0,3.075 ; back 2 ****
	dq 0.925,3.97,3.025 ; back 3 ***
	dq 0.925,3.94,2.975 ; back 4 **
	dq 0.975,3.91,2.925 ; back 5 *
	dq 1.025,3.91,2.925 ; back 6 *
	dq 1.075,3.94,2.975 ; back 7 **
	dq 1.075,3.97,3.025 ; back 8 ***
	dq 0.3,3.55,3.01 ; wing 1 tip fwd upr
	dq 0.3,3.6,3.01 ; wing 1 tip aft upr
	dq 0.3,3.55,2.99 ; wing 1 tip fwd lwr
	dq 0.3,3.6,2.99 ; wing 1 tip aft lwr
	dq 0.925,3.4,3.01 ; wing 1 con fwd upr
	dq 0.925,3.55,3.01 ; wing 1 con aft upr
	dq 0.925,3.4,2.99 ; wing 1 con fwd lwr
	dq 0.925,3.55,2.99 ; wing 1 con aft lwr
	dq 1.7,3.55,3.01 ; wing 2 tip fwd upr
	dq 1.7,3.6,3.01 ; wing 2 tip aft upr
	dq 1.7,3.55,2.99 ; wing 2 tip fwd lwr
	dq 1.7,3.6,2.99 ; wing 2 tip aft lwr
	dq 1.075,3.4,3.01 ; wing 2 con fwd upr
	dq 1.075,3.55,3.01 ; wing 2 con aft upr
	dq 1.075,3.4,2.99 ; wing 2 con fwd lwr
	dq 1.075,3.55,2.99 ; wing 2 con aft lwr
	; horiz tail
	dq 0.75,3.9,3.01 ; wing 1 tip fwd upr
	dq 0.75,3.95,3.01 ; wing 1 tip aft upr
	dq 0.75,3.9,2.99 ; wing 1 tip fwd lwr
	dq 0.75,3.95,2.99 ; wing 1 tip aft lwr
	dq 0.925,3.85,3.01 ; wing 1 con fwd upr
	dq 0.925,3.95,3.01 ; wing 1 con aft upr
	dq 0.925,3.85,2.99 ; wing 1 con fwd lwr
	dq 0.925,3.95,2.99 ; wing 1 con aft lwr
	dq 1.25,3.9,3.01 ; wing 2 tip fwd upr
	dq 1.25,3.95,3.01 ; wing 2 tip aft upr
	dq 1.25,3.9,2.99 ; wing 2 tip fwd lwr
	dq 1.25,3.95,2.99 ; wing 2 tip aft lwr
	dq 1.075,3.85,3.01 ; wing 2 con fwd upr
	dq 1.075,3.95,3.01 ; wing 2 con aft upr
	dq 1.075,3.85,2.99 ; wing 2 con fwd lwr
	dq 1.075,3.95,2.99 ; wing 2 con aft lwr
	; vert tail
	dq 0.99,4.0,3.075 ; aft vert 1
	dq 1.01,4.0,3.075 ; aft vert 2
	dq 0.99,3.8,3.075 ; aft vert 1
	dq 1.01,3.8,3.075 ; aft vert 2
	dq 0.99,4.0,3.3 ; aft vert 1
	dq 1.01,4.0,3.3 ; aft vert 2
	dq 0.99,3.95,3.3 ; aft vert 1
	dq 1.01,3.95,3.3 ; aft vert 2

.plane_2_points:
	dq -1.0,3.9,3.0 ; pointy nose
	dq -1.025,4.0,3.075 ; front 1
	dq -0.975,4.0,3.075 ; front 2
	dq -0.925,4.0,3.025 ; front 3
	dq -0.925,4.0,2.975 ; front 4
	dq -0.975,4.0,2.925 ; front 5
	dq -1.025,4.0,2.925 ; front 6
	dq -1.075,4.0,2.975 ; front 7
	dq -1.075,4.0,3.025 ; front 8
	dq -1.025,5.0,3.075 ; back 1 ****
	dq -0.975,5.0,3.075 ; back 2 ****
	dq -0.925,4.97,3.025 ; back 3 ***
	dq -0.925,4.94,2.975 ; back 4 **
	dq -0.975,4.91,2.925 ; back 5 *
	dq -1.025,4.91,2.925 ; back 6 *
	dq -1.075,4.94,2.975 ; back 7 **
	dq -1.075,4.97,3.025 ; back 8 ***
	dq -0.3,4.55,3.01 ; wing 1 tip fwd upr
	dq -0.3,4.6,3.01 ; wing 1 tip aft upr
	dq -0.3,4.55,2.99 ; wing 1 tip fwd lwr
	dq -0.3,4.6,2.99 ; wing 1 tip aft lwr
	dq -0.925,4.4,3.01 ; wing 1 con fwd upr
	dq -0.925,4.55,3.01 ; wing 1 con aft upr
	dq -0.925,4.4,2.99 ; wing 1 con fwd lwr
	dq -0.925,4.55,2.99 ; wing 1 con aft lwr
	dq -1.7,4.55,3.01 ; wing 2 tip fwd upr
	dq -1.7,4.6,3.01 ; wing 2 tip aft upr
	dq -1.7,4.55,2.99 ; wing 2 tip fwd lwr
	dq -1.7,4.6,2.99 ; wing 2 tip aft lwr
	dq -1.075,4.4,3.01 ; wing 2 con fwd upr
	dq -1.075,4.55,3.01 ; wing 2 con aft upr
	dq -1.075,4.4,2.99 ; wing 2 con fwd lwr
	dq -1.075,4.55,2.99 ; wing 2 con aft lwr
	; horiz tail
	dq -0.75,4.9,3.01 ; wing 1 tip fwd upr
	dq -0.75,4.95,3.01 ; wing 1 tip aft upr
	dq -0.75,4.9,2.99 ; wing 1 tip fwd lwr
	dq -0.75,4.95,2.99 ; wing 1 tip aft lwr
	dq -0.925,4.85,3.01 ; wing 1 con fwd upr
	dq -0.925,4.95,3.01 ; wing 1 con aft upr
	dq -0.925,4.85,2.99 ; wing 1 con fwd lwr
	dq -0.925,4.95,2.99 ; wing 1 con aft lwr
	dq -1.25,4.9,3.01 ; wing 2 tip fwd upr
	dq -1.25,4.95,3.01 ; wing 2 tip aft upr
	dq -1.25,4.9,2.99 ; wing 2 tip fwd lwr
	dq -1.25,4.95,2.99 ; wing 2 tip aft lwr
	dq -1.075,4.85,3.01 ; wing 2 con fwd upr
	dq -1.075,4.95,3.01 ; wing 2 con aft upr
	dq -1.075,4.85,2.99 ; wing 2 con fwd lwr
	dq -1.075,4.95,2.99 ; wing 2 con aft lwr
	; vert tail
	dq -0.99,5.0,3.075 ; aft vert 1
	dq -1.01,5.0,3.075 ; aft vert 2
	dq -0.99,4.8,3.075 ; aft vert 1
	dq -1.01,4.8,3.075 ; aft vert 2
	dq -0.99,5.0,3.3 ; aft vert 1
	dq -1.01,5.0,3.3 ; aft vert 2
	dq -0.99,4.95,3.3 ; aft vert 1
	dq -1.01,4.95,3.3 ; aft vert 2

.plane_edges:
	dq 0,1
	dq 0,2
	dq 0,3
	dq 0,4
	dq 0,5
	dq 0,6
	dq 0,7
	dq 0,8
	dq 1,2
	dq 2,3
	dq 3,4
	dq 4,5
	dq 5,6
	dq 6,7
	dq 7,8
	dq 8,1
	dq 9,10
	dq 10,11
	dq 11,12
	dq 12,13
	dq 13,14
	dq 14,15
	dq 15,16
	dq 16,9
	dq 1,9
	dq 2,10
	dq 3,11
	dq 4,12
	dq 5,13
	dq 6,14
	dq 7,15
	dq 8,16
	; right wing
	dq 17,18
	dq 19,20
	dq 17,19
	dq 18,20
	dq 21,22
	dq 23,24
	dq 21,23
	dq 22,24
	dq 17,21
	dq 18,22
	dq 19,23
	dq 20,24
	; left wing	
	dq 25,26
	dq 27,28
	dq 25,27
	dq 26,28
	dq 29,30
	dq 31,32
	dq 29,31
	dq 30,32
	dq 25,29
	dq 26,30
	dq 27,31
	dq 28,32
	; right tail
	dq 33,34
	dq 35,36
	dq 33,35
	dq 34,36
	dq 37,38
	dq 39,40
	dq 37,39
	dq 38,40
	dq 33,37
	dq 34,38
	dq 35,39
	dq 36,40
	; left tail
	dq 41,42
	dq 43,44
	dq 41,43
	dq 42,44
	dq 45,46
	dq 47,48
	dq 45,47
	dq 46,48
	dq 41,45
	dq 42,46
	dq 43,47
	dq 44,48
	; vert tail
	dq 49,50
	dq 51,52
	dq 49,51
	dq 50,52
	dq 53,54
	dq 55,56
	dq 53,55
	dq 54,56
	dq 49,53
	dq 50,54
	dq 51,55
	dq 52,56

.explosive_1_points:
	dq 1.05,0.05,3.45
	dq 0.95,0.05,3.45
	dq 0.95,-0.05,3.45
	dq 1.05,-0.05,3.45
	dq 1.05,0.05,3.55
	dq 0.95,0.05,3.55
	dq 0.95,-0.05,3.55
	dq 1.05,-0.05,3.55
.explosive_2_points:
	dq 1.05,0.05,2.45
	dq 0.95,0.05,2.45
	dq 0.95,-0.05,2.45
	dq 1.05,-0.05,2.45
	dq 1.05,0.05,2.55
	dq 0.95,0.05,2.55
	dq 0.95,-0.05,2.55
	dq 1.05,-0.05,2.55
.explosive_3_points:
	dq 1.05,0.05,1.45
	dq 0.95,0.05,1.45
	dq 0.95,-0.05,1.45
	dq 1.05,-0.05,1.45
	dq 1.05,0.05,1.55
	dq 0.95,0.05,1.55
	dq 0.95,-0.05,1.55
	dq 1.05,-0.05,1.55
.explosive_4_points:
	dq 1.05,0.05,0.45
	dq 0.95,0.05,0.45
	dq 0.95,-0.05,0.45
	dq 1.05,-0.05,0.45
	dq 1.05,0.05,0.55
	dq 0.95,0.05,0.55
	dq 0.95,-0.05,0.55
	dq 1.05,-0.05,0.55
.explosive_5_points:
	dq -1.05,0.05,3.45
	dq -0.95,0.05,3.45
	dq -0.95,-0.05,3.45
	dq -1.05,-0.05,3.45
	dq -1.05,0.05,3.55
	dq -0.95,0.05,3.55
	dq -0.95,-0.05,3.55
	dq -1.05,-0.05,3.55
.explosive_6_points:
	dq -1.05,0.05,2.45
	dq -0.95,0.05,2.45
	dq -0.95,-0.05,2.45
	dq -1.05,-0.05,2.45
	dq -1.05,0.05,2.55
	dq -0.95,0.05,2.55
	dq -0.95,-0.05,2.55
	dq -1.05,-0.05,2.55
.explosive_7_points:
	dq -1.05,0.05,1.45
	dq -0.95,0.05,1.45
	dq -0.95,-0.05,1.45
	dq -1.05,-0.05,1.45
	dq -1.05,0.05,1.55
	dq -0.95,0.05,1.55
	dq -0.95,-0.05,1.55
	dq -1.05,-0.05,1.55
.explosive_8_points:
	dq -1.05,0.05,0.45
	dq -0.95,0.05,0.45
	dq -0.95,-0.05,0.45
	dq -1.05,-0.05,0.45
	dq -1.05,0.05,0.55
	dq -0.95,0.05,0.55
	dq -0.95,-0.05,0.55
	dq -1.05,-0.05,0.55
.explosive_9_points:
	dq -3.05,0.05,1.45
	dq -2.95,0.05,1.45
	dq -2.95,-0.05,1.45
	dq -3.05,-0.05,1.45
	dq -3.05,0.05,1.55
	dq -2.95,0.05,1.55
	dq -2.95,-0.05,1.55
	dq -3.05,-0.05,1.55
.explosive_10_points:
	dq -3.05,0.05,0.45
	dq -2.95,0.05,0.45
	dq -2.95,-0.05,0.45
	dq -3.05,-0.05,0.45
	dq -3.05,0.05,0.55
	dq -2.95,0.05,0.55
	dq -2.95,-0.05,0.55
	dq -3.05,-0.05,0.55

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)

