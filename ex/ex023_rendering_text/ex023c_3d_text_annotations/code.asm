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

%include "lib/mem/heap_init.asm"
; void heap_init(void);

%include "lib/io/bitmap/set_text.asm"
; void set_text(void* {rdi}, int {esi}, int {edx}, int {ecx},
;	 int {r8d}, int {r9d}, int {r10d}, char* {r11}, void* {r12});

%include "lib/io/bitmap/SCHIZOFONT.asm"

%include "lib/io/framebuffer/framebuffer_init.asm"
; void framebuffer_init(void);

%include "lib/io/framebuffer/framebuffer_3d_render_loop.asm"

%include "lib/io/bitmap/set_line.asm"
; void set_line(void* {rdi}, int {esi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});


;%include "lib/sys/exit.asm"
;%include "lib/io/print_float.asm"
;%include "lib/io/print_int_d.asm"

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
	mov rsi,.plane_geometry
	mov rdx,DRAW_CROSS_CURSOR
	call framebuffer_3d_render_init

.loop:
	call framebuffer_3d_render_loop
	jmp .loop

.text_1:
	db `Jeffrey Epstein`,0

.text_2:
	db `underage minor`,0

.text_3:
	db `William Clinton`,0

.text_4:
	db `Lolita Express\n(Boeing 727)`,0

.perspective_structure:
	dq 1.00 ; lookFrom_x	
	dq 4.00 ; lookFrom_y	
	dq 5.00 ; lookFrom_z	
	dq 1.00 ; lookAt_x	
	dq 3.50 ; lookAt_y	
	dq 3.00 ; lookAt_z	
	dq 0.0 ; upDir_x	
	dq 0.0 ; upDir_y	
	dq 1.0 ; upDir_z	
	dq 0.8	; zoom

.plane_geometry:
	dq .text_1_geometry ; next geometry in linked list
	dq .plane_structure ; address of point/edge/face structure
	dq 0x1FFFFFFFF ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.text_1_geometry:
	dq .text_1_leader_geometry ; next geometry in linked list
	dq .text_1_structure ; address of point/edge/face structure
	dq 0x1FFFF0000 ; color (0xARGB)
	db 0b00001000 ; type of structure to render

.text_1_leader_geometry:
	dq .text_2_geometry ; next geometry in linked list
	dq .text_1_leader_structure ; address of point/edge/face structure
	dq 0x1FFFF0000 ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.text_2_geometry:
	dq .text_2_leader_geometry ; next geometry in linked list
	dq .text_2_structure ; address of point/edge/face structure
	dq 0x1FF00FF00 ; color (0xARGB)
	db 0b00001000 ; type of structure to render

.text_2_leader_geometry:
	dq .text_3_geometry ; next geometry in linked list
	dq .text_2_leader_structure ; address of point/edge/face structure
	dq 0x1FF00FF00 ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.text_3_geometry:
	dq .text_3_leader_geometry ; next geometry in linked list
	dq .text_3_structure ; address of point/edge/face structure
	dq 0x1FF0000FF ; color (0xARGB)
	db 0b00001000 ; type of structure to render

.text_3_leader_geometry:
	dq .text_4_geometry ; next geometry in linked list
	dq .text_3_leader_structure ; address of point/edge/face structure
	dq 0x1FF0000FF ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.text_4_geometry:
	dq .text_4_leader_geometry ; next geometry in linked list
	dq .text_4_structure ; address of point/edge/face structure
	dq 0x1FF00FFFF ; color (0xARGB)
	db 0b00001000 ; type of structure to render

.text_4_leader_geometry:
	dq 0 ; next geometry in linked list
	dq .text_4_leader_structure ; address of point/edge/face structure
	dq 0x1FF00FFFF ; color (0xARGB)
	db 0b00000010 ; type of structure to render

.plane_structure:
	dq 56 ; number of points (N)
	dq 92 ; number of edges (M)
	dq .plane_points ; starting address of point array (3N elements)
	dq .plane_edges ; starting address of edge array (2M elements)

.text_1_structure:
	dq .text_1_position ; address of 24-byte (x,y,z) position
	dq .text_1 ; address of null-terminated string
	dq SCHIZOFONT ; address of font definition
	dq 4 ; font-size (scaling of 8px)

.text_1_leader_structure:
	dq 2 ; number of points (N)
	dq 1 ; number of edges (M)
	dq .text_1_leader_points ; starting address of point array (3N elements)
	dq .text_edges ; starting address of edge array (2M elements)

.text_2_structure:
	dq .text_2_position ; address of 24-byte (x,y,z) position
	dq .text_2 ; address of null-terminated string
	dq SCHIZOFONT ; address of font definition
	dq 4 ; font-size (scaling of 8px)

.text_2_leader_structure:
	dq 2 ; number of points (N)
	dq 1 ; number of edges (M)
	dq .text_2_leader_points ; starting address of point array (3N elements)
	dq .text_edges ; starting address of edge array (2M elements)

.text_3_structure:
	dq .text_3_position ; address of 24-byte (x,y,z) position
	dq .text_3 ; address of null-terminated string
	dq SCHIZOFONT ; address of font definition
	dq 4 ; font-size (scaling of 8px)

.text_3_leader_structure:
	dq 2 ; number of points (N)
	dq 1 ; number of edges (M)
	dq .text_3_leader_points ; starting address of point array (3N elements)
	dq .text_edges ; starting address of edge array (2M elements)

.text_4_structure:
	dq .text_4_position ; address of 24-byte (x,y,z) position
	dq .text_4 ; address of null-terminated string
	dq SCHIZOFONT ; address of font definition
	dq 4 ; font-size (scaling of 8px)

.text_4_leader_structure:
	dq 2 ; number of points (N)
	dq 1 ; number of edges (M)
	dq .text_4_leader_points ; starting address of point array (3N elements)
	dq .text_edges ; starting address of edge array (2M elements)

.text_1_position:
	dq 0.2,3.2,3.0

.text_1_leader_points:
	dq 0.2,3.2,3.0
	dq 1.0,3.2,3.0

.text_2_position:
	dq 0.2,3.65,3.0

.text_2_leader_points:
	dq 0.2,3.69,3.0
	dq 1.0,3.69,3.0

.text_3_position:
	dq 0.2,3.75,3.0

.text_3_leader_points:
	dq 0.2,3.75,3.0
	dq 1.0,3.75,3.0

.text_4_position:
	dq 0.5,2.7,3.0

.text_4_leader_points:
	dq 0.5,2.7,3.0
	dq 1.0,2.9,3.0

.text_edges:
	dq 0,1

.plane_points:
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

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)
