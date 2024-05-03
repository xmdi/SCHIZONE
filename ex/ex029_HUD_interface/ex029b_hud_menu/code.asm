;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;DEFINITIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%define LOAD_ADDRESS 0x00020000 ; pretty much any number >0 works
%define CODE_SIZE END-(LOAD_ADDRESS+0x78) ; everything beyond HEADER is code
%define PRINT_BUFFER_SIZE 4096
%define HEAP_SIZE 0x4000000 ; ~64 MB

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

%include "lib/io/framebuffer/framebuffer_hud_init.asm"

%include "lib/io/framebuffer/perspective/framebuffer_3d_render_depth_init.asm"

%include "lib/io/framebuffer/perspective/framebuffer_3d_render_depth_loop.asm"

%include "lib/io/framebuffer/framerate/framerate_poll.asm"

%include "lib/mem/memset.asm"
; void memset(void* {rdi}, char {sil}, ulong {rdx});

%include "lib/mem/memcopy.asm"

%include "lib/io/bitmap/set_text.asm"
%include "lib/io/bitmap/SCHIZOFONT.asm"

%include "lib/io/print_buffer_flush_to_memory.asm"

;%include "lib/io/print_array_float.asm"
%include "lib/io/print_float.asm"
%include "lib/io/print_int_d.asm"

%include "lib/io/print_stack.asm"

%include "lib/sys/exit.asm"

%include "lib/io/framebuffer/framebuffer_mouse_init.asm"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; NOTE: NEED TO RUN THIS AS SUDO

RESET_VIEW:
	
	push rdi
	push rsi
	push rdx
	push r15

	mov rdi,START.perspective_structure
	mov rsi,START.original_perspective_structure
	mov rdx,80
	call memcopy

	mov rdi,framebuffer_3d_render_depth_init.perspective_old
	mov rsi,START.perspective_structure
	mov rdx,80
	call memcopy

	mov rdi,framebuffer_3d_render_depth_init.view_axes_old
	mov rsi,START.original_view_axes
	mov rdx,72
	call memcopy

	mov rdi,framebuffer_3d_render_depth_init.view_axes
	mov rsi,START.original_view_axes
	mov rdx,72
	call memcopy
	
	; clear the background first
	mov rdi,[framebuffer_3d_render_depth_init.intermediate_buffer_address]
	xor sil,sil
	mov rdx,[framebuffer_init.framebuffer_size]
	call memset

	; clear screen
	xor rdi,rdi	
	call framebuffer_clear
	call framebuffer_flush

	mov rdi,.ret_addr
	push rdi

	push rdi
	push rsi
	push rdx
	push rcx
	push rax
	push r8
	push r9
	push r13
	push r14
	push r15
	sub rsp,112
	movdqu [rsp+0],xmm0
	movdqu [rsp+16],xmm1
	movdqu [rsp+32],xmm2
	movdqu [rsp+48],xmm7
	movdqu [rsp+64],xmm8
	movdqu [rsp+80],xmm14
	movdqu [rsp+96],xmm15

	mov r15,[framebuffer_3d_render_depth_init.perspective_structure_address]

	jmp framebuffer_3d_render_depth_loop.draw_wires

.ret_addr:
	
	pop r15
	pop rdx
	pop rsi
	pop rdi

	ret

QUIT:
	
	; clear screen
	xor rdi,rdi	
	call framebuffer_clear
	call framebuffer_flush

	; shut down
	xor dil,dil
	call exit

CHANGE_SHOW_HIDE_TEXT_AND_TOGGLE_VISIBILITY:


	push rdi
	push rsi
	push rdx

	mov rdi,[rsp+32]

	push rdi
	call TOGGLE_ELEMENT_AND_DESCENDANT_VISIBILITY
	pop rdi

	add rdi,8
	mov rdi,[rdi]

	call print_buffer_reset
	
	mov rsi,.show_string
	mov rdx,.hide_string	

	cmp byte [rdi],byte "S"
	cmove rsi,rdx

	; if it says Show, make it say Hide, vice versa

	mov rdx,4
	call print_chars
	call print_buffer_flush_to_memory


	pop rdx
	pop rsi
	pop rdi
	ret

.show_string:
	db `Show`
.hide_string:
	db `Hide`

TOGGLE_ELEMENT_AND_DESCENDANT_VISIBILITY:
	push rdi
	push rbp
	mov rbp,rsp

	mov rdi,[rsp+24]	; address of onClick data
	mov rdi,[rdi]	

	xor byte [rdi],0b10000000
	push rdi
	add rdi,9		; pointer to first descendant
	mov rdi,[rdi]

	call .TOGGLE_COUSINS_VISIBILITY

	mov rsp,rbp
	pop rbp
	pop rdi
	ret

.TOGGLE_COUSINS_VISIBILITY: ; [rdi] contains address of first cousin to toggle
			 	; this address gets "called" every time we find a child
				; expects parent address on the stack
	
	xor byte [rdi], byte 0b10000000 ; toggle this element's visibility
	
	; if children, recurse on them
	cmp qword [rdi+9], qword 0
	je .no_rectangle_kids

	push rdi
	
	mov rdi,[rdi+9]

	call .TOGGLE_COUSINS_VISIBILITY

	pop rdi

.no_rectangle_kids:
	; goto cousin
	mov rdi,[rdi+1]
	cmp rdi,0
	je .no_cousins	
	jmp .TOGGLE_COUSINS_VISIBILITY

.no_cousins:
.ret:

	ret


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

	mov rdi,.original_view_axes
	mov rsi,framebuffer_3d_render_depth_init.view_axes
	mov rdx,72
	call memcopy

	; initialize HUD
	call framebuffer_hud_init

	; enable HUD
	mov al,1
	mov [framebuffer_hud_init.hud_enabled],al

	mov rax,.HUD_ELEMENT_FOR_MENU
	mov [framebuffer_hud_init.hud_head],rax

	mov rax,.HUD_ELEMENT_FOR_MENU ; TODO updoot
	mov [framebuffer_hud_init.hud_tail],rax

.loop:

	call framebuffer_3d_render_depth_loop

	call framerate_poll
	
	push rdi
	push rsi
	push rdx	

	call print_buffer_reset
	
	; framerate counter update

	; reset string
	mov rdi,.framerate_string+5
	mov sil,0
	mov rdx,20
	call memset	

	mov rsi,4
	movsd xmm0,[framerate_poll.framerate]
	call print_float

	mov rdi,.framerate_string+5	
	call print_buffer_flush_to_memory

	; mouse x position

	; reset string
	mov rdi,.mouse_x_string+3
	mov sil,0
	mov rdx,5
	call memset	

	mov esi,[framebuffer_mouse_init.mouse_x]
	call print_int_d

	mov rdi,.mouse_x_string+3	
	call print_buffer_flush_to_memory

	; mouse y position

	; reset string
	mov rdi,.mouse_y_string+3
	mov sil,0
	mov rdx,5
	call memset	

	mov esi,[framebuffer_mouse_init.mouse_y]
	call print_int_d

	mov rdi,.mouse_y_string+3	
	call print_buffer_flush_to_memory

	pop rdx
	pop rsi
	pop rdi

	jmp .loop

.HUD_ELEMENT_FOR_MENU:
	db 0b10000000 ; VISIBLE TOP LEVEL ELEMENT
	dq .HUD_ELEMENT_FOR_FILE_SUBMENU ; address of cousin (next top-level HUD element)
	dq .FILE_RECTANGLE ; address of child element
	dw 0 ; X start coordinate for all children
	dw 1040 ; Y start coordinate for all children

.FILE_RECTANGLE:
	db 0b10000001 ; VISIBLE RECTANGLE
	dq .VIEW_RECTANGLE ; address of cousin HUD element
	dq .FILE_TEXT ; address of child HUD element
	dw 0 ; X0 displacement from parent
	dw 0 ; Y0 displacement from parent
	dw 145 ; X1 displacement from parent
	dw 40 ; Y1 displacement from parent
	dd 0xFFBBBBBB ; color of rectangle
	dq TOGGLE_ELEMENT_AND_DESCENDANT_VISIBILITY ; onClick function pointer
	dq .HUD_ELEMENT_FOR_FILE_SUBMENU ; space for onClick function input data/params

.FILE_TEXT:
	db 0b10000010 ; VISIBLE TEXT
	dq 0 ; address of cousin HUD element
	dq 0 ; address of child HUD element. NOTE: UNUSED FOR TEXT ELEMENTS
	dw 10 ; X displacement from parent
	dw 6 ; Y displacement from parent
	db 4 ; font scaling
	dq SCHIZOFONT ; font definition pointer
	dd 0xFF000000 ; color of text
	dq .file_string ; null-terminated char array to write

.file_string:
	db `File`,0

.VIEW_RECTANGLE:
	db 0b10000001 ; VISIBLE RECTANGLE
	dq 0 ; address of cousin HUD element
	dq .VIEW_TEXT ; address of child HUD element
	dw 160 ; X0 displacement from parent
	dw 0 ; Y0 displacement from parent
	dw 305 ; X1 displacement from parent
	dw 40 ; Y1 displacement from parent
	dd 0xFFBBBBBB ; color of rectangle
	dq TOGGLE_ELEMENT_AND_DESCENDANT_VISIBILITY ; onClick function pointer
	dq .HUD_ELEMENT_FOR_VIEW_SUBMENU ; space for onClick function input data/params

.VIEW_TEXT:
	db 0b10000010 ; VISIBLE TEXT
	dq 0 ; address of cousin HUD element
	dq 0 ; address of child HUD element. NOTE: UNUSED FOR TEXT ELEMENTS
	dw 10 ; X displacement from parent
	dw 6 ; Y displacement from parent
	db 4 ; font scaling
	dq SCHIZOFONT ; font definition pointer
	dd 0xFF000000 ; color of text
	dq .view_string ; null-terminated char array to write

.view_string:
	db `View`,0

.HUD_ELEMENT_FOR_FILE_SUBMENU:
	db 0b00000000 ; VISIBLE TOP LEVEL ELEMENT
	dq .HUD_ELEMENT_FOR_VIEW_SUBMENU ; address of cousin (next top-level HUD element)
	dq .FILE_QUIT_RECTANGLE ; address of child element
	dw 0 ; X start coordinate for all children
	dw 990 ; Y start coordinate for all children

.FILE_QUIT_RECTANGLE:
	db 0b00000001 ; VISIBLE RECTANGLE
	dq 0 ; address of cousin HUD element
	dq .FILE_QUIT_TEXT ; address of child HUD element
	dw 0 ; X0 displacement from parent
	dw 0 ; Y0 displacement from parent
	dw 145 ; X1 displacement from parent
	dw 40 ; Y1 displacement from parent
	dd 0xFFBBBBBB ; color of rectangle
	dq QUIT ; onClick function pointer
	; space for onClick function input data/params

.FILE_QUIT_TEXT:
	db 0b00000010 ; VISIBLE TEXT
	dq 0 ; address of cousin HUD element
	dq 0 ; address of child HUD element. NOTE: UNUSED FOR TEXT ELEMENTS
	dw 10 ; X displacement from parent
	dw 6 ; Y displacement from parent
	db 4 ; font scaling
	dq SCHIZOFONT ; font definition pointer
	dd 0xFFFFFFFF ; color of text
	dq .file_quit_string ; null-terminated char array to write

.file_quit_string:
	db `Quit`,0

.HUD_ELEMENT_FOR_VIEW_SUBMENU:
	db 0b00000000 ; VISIBLE TOP LEVEL ELEMENT
	dq .HUD_ELEMENT_FOR_FPS ; address of cousin (next top-level HUD element)
	dq .VIEW_RESET_RECTANGLE ; address of child element
	dw 160 ; X start coordinate for all children
	dw 890 ; Y start coordinate for all children

.VIEW_RESET_RECTANGLE:
	db 0b00000001 ; VISIBLE RECTANGLE
	dq .VIEW_TOGGLE_FPS_RECTANGLE ; address of cousin HUD element
	dq .VIEW_RESET_TEXT ; address of child HUD element
	dw 0 ; X0 displacement from parent
	dw 0 ; Y0 displacement from parent
	dw 335 ; X1 displacement from parent
	dw 40 ; Y1 displacement from parent
	dd 0xFFBBBBBB ; color of rectangle
	dq RESET_VIEW ; onClick function pointer
	; space for onClick function input data/params

.VIEW_TOGGLE_FPS_RECTANGLE:
	db 0b00000001 ; VISIBLE RECTANGLE
	dq .VIEW_TOGGLE_MOUSE_POSITION_RECTANGLE ; address of cousin HUD element
	dq .VIEW_TOGGLE_FPS_TEXT ; address of child HUD element
	dw 0 ; X0 displacement from parent
	dw 50 ; Y0 displacement from parent
	dw 270 ; X1 displacement from parent
	dw 90 ; Y1 displacement from parent
	dd 0xFFBBBBBB ; color of rectangle	
	dq CHANGE_SHOW_HIDE_TEXT_AND_TOGGLE_VISIBILITY ; onClick function pointer
	dq .HUD_ELEMENT_FOR_FPS ; space for onClick function input data/params
	dq .view_toggle_fps_string ; space for onClick function input data/params

.VIEW_TOGGLE_MOUSE_POSITION_RECTANGLE:
	db 0b00000001 ; VISIBLE RECTANGLE
	dq 0 ; address of cousin HUD element
	dq .VIEW_TOGGLE_MOUSE_POSITION_TEXT ; address of child HUD element
	dw 0 ; X0 displacement from parent
	dw 100 ; Y0 displacement from parent
	dw 460 ; X1 displacement from parent
	dw 140 ; Y1 displacement from parent
	dd 0xFFBBBBBB ; color of rectangle
	dq CHANGE_SHOW_HIDE_TEXT_AND_TOGGLE_VISIBILITY ; onClick function pointer
	dq .HUD_ELEMENT_FOR_MOUSE ; space for onClick function input data/params
	dq .view_toggle_mouse_position_string ; space for onClick function input data/params

.VIEW_RESET_TEXT:
	db 0b00000010 ; VISIBLE TEXT
	dq 0 ; address of cousin HUD element
	dq 0 ; address of child HUD element. NOTE: UNUSED FOR TEXT ELEMENTS
	dw 10 ; X displacement from parent
	dw 6 ; Y displacement from parent
	db 4 ; font scaling
	dq SCHIZOFONT ; font definition pointer
	dd 0xFFFFFFFF ; color of text
	dq .view_reset_string ; null-terminated char array to write

.view_reset_string:
	db `Reset View`,0

.VIEW_TOGGLE_FPS_TEXT:
	db 0b00000010 ; VISIBLE TEXT
	dq 0 ; address of cousin HUD element
	dq 0 ; address of child HUD element. NOTE: UNUSED FOR TEXT ELEMENTS
	dw 10 ; X displacement from parent
	dw 6 ; Y displacement from parent
	db 4 ; font scaling
	dq SCHIZOFONT ; font definition pointer
	dd 0xFFFFFFFF ; color of text
	dq .view_toggle_fps_string ; null-terminated char array to write

.view_toggle_fps_string:
	db `Show FPS`,0

.VIEW_TOGGLE_MOUSE_POSITION_TEXT:
	db 0b00000010 ; VISIBLE TEXT
	dq 0 ; address of cousin HUD element
	dq 0 ; address of child HUD element. NOTE: UNUSED FOR TEXT ELEMENTS
	dw 10 ; X displacement from parent
	dw 6 ; Y displacement from parent
	db 4 ; font scaling
	dq SCHIZOFONT ; font definition pointer
	dd 0xFFFFFFFF ; color of text
	dq .view_toggle_mouse_position_string ; null-terminated char array to write

.view_toggle_mouse_position_string:
	db `Show Mouse Pos`,0

.HUD_ELEMENT_FOR_FPS:
	db 0b00000000 ; VISIBLE TOP LEVEL ELEMENT
	dq .HUD_ELEMENT_FOR_MOUSE ; address of cousin (next top-level HUD element)
	dq .FPS_RECTANGLE ; address of child element
	dw 1580 ; X start coordinate for all children
	dw 0 ; Y start coordinate for all children

.FPS_RECTANGLE:
	db 0b00000001 ; VISIBLE RECTANGLE
	dq 0 ; address of cousin HUD element
	dq .FPS_TEXT ; address of child HUD element
	dw 0 ; X0 displacement from parent
	dw 0 ; Y0 displacement from parent
	dw 338 ; X1 displacement from parent
	dw 40 ; Y1 displacement from parent
	dd 0xFFFA2DD0 ; color of rectangle
	dq 0 ; onClick function pointer
	; space for onClick function input data/params

.FPS_TEXT:
	db 0b00000010 ; VISIBLE TEXT
	dq 0 ; address of cousin HUD element
	dq 0 ; address of child HUD element. NOTE: UNUSED FOR TEXT ELEMENTS
	dw 10 ; X displacement from parent
	dw 6 ; Y displacement from parent
	db 4 ; font scaling
	dq SCHIZOFONT ; font definition pointer
	dd 0xFFFFFFFF ; color of text
	dq .framerate_string ; null-terminated char array to write

.framerate_string:
	db `FPS: `
	times 20 db 0

.HUD_ELEMENT_FOR_MOUSE:
	db 0b00000000 ; VISIBLE TOP LEVEL ELEMENT
	dq 0 ; address of cousin (next top-level HUD element)
	dq .MOUSE_RECTANGLE ; address of child element
	dw 1000 ; X start coordinate for all children
	dw 0 ; Y start coordinate for all children

.MOUSE_RECTANGLE:
	db 0b00000001 ; VISIBLE RECTANGLE
	dq 0 ; address of cousin HUD element
	dq .MOUSE_TEXT_X ; address of child HUD element
	dw 0 ; X0 displacement from parent
	dw 0 ; Y0 displacement from parent
	dw 510 ; X1 displacement from parent
	dw 40 ; Y1 displacement from parent
	dd 0xFFFFA500 ; color of rectangle
	dq 0 ; onClick function pointer
	; space for onClick function input data/params

.MOUSE_TEXT_X:
	db 0b00000010 ; VISIBLE TEXT
	dq .MOUSE_TEXT_Y ; address of cousin HUD element
	dq 0 ; address of child HUD element. NOTE: UNUSED FOR TEXT ELEMENTS
	dw 10 ; X displacement from parent
	dw 6 ; Y displacement from parent
	db 4 ; font scaling
	dq SCHIZOFONT ; font definition pointer
	dd 0xFF0000FF ; color of text
	dq .mouse_x_string ; null-terminated char array to write

.MOUSE_TEXT_Y:
	db 0b00000010 ; VISIBLE TEXT
	dq 0 ; address of cousin HUD element
	dq 0 ; address of child HUD element. NOTE: UNUSED FOR TEXT ELEMENTS
	dw 280 ; X displacement from parent
	dw 6 ; Y displacement from parent
	db 4 ; font scaling
	dq SCHIZOFONT ; font definition pointer
	dd 0xFF0000FF ; color of text
	dq .mouse_y_string ; null-terminated char array to write

.mouse_x_string:
	db `X: `
	times 5 db 0

.mouse_y_string:
	db `Y: `
	times 5 db 0

.original_perspective_structure:
	dq 5.00 ; lookFrom_x	
	dq -10.00 ; lookFrom_y	
	dq 5.00 ; lookFrom_z	
	dq 0.00 ; lookAt_x	
	dq 0.00 ; lookAt_y	
	dq 2.00 ; lookAt_z	
	dq 0.0 ; upDir_x	
	dq 0.0 ; upDir_y	
	dq 1.0 ; upDir_z	
	dq 1.3	; zoom

.perspective_structure:
	dq 5.00 ; lookFrom_x	
	dq -10.00 ; lookFrom_y	
	dq 5.00 ; lookFrom_z	
	dq 0.00 ; lookAt_x	
	dq 0.00 ; lookAt_y	
	dq 2.00 ; lookAt_z	
	dq 0.0 ; upDir_x	
	dq 0.0 ; upDir_y	
	dq 1.0 ; upDir_z	
	dq 1.3	; zoom

.original_view_axes:
	times 9 dq 0

.cross_geometry:
	dq .cube_geometry ; next geometry in linked list
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
	dq 0 ; next geometry in linked list
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
	dq 6,3,7,0xFFFFFFFF ; back

.newline:
	db `\n`
		
END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)

