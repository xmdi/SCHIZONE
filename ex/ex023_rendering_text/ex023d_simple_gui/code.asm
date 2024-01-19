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

%include "lib/mem/memcopy.asm"
; void memcopy(long* {rdi}, long* {rsi}, ulong {rdx});

%include "lib/io/bitmap/set_text.asm"
; void set_text(void* {rdi}, int {esi}, int {edx}, int {ecx},
;	 int {r8d}, int {r9d}, int {r10d}, char* {r11}, void* {r12});

%include "lib/io/bitmap/SCHIZOFONT.asm"

%include "lib/io/framebuffer/framebuffer_init.asm"
; void framebuffer_init(void);

%include "lib/io/framebuffer/framebuffer_mouse_init.asm"
; void framebuffer_mouse_init(void);

%include "lib/io/framebuffer/framebuffer_clear.asm"
; void framebuffer_clear(uint {rdi});

%include "lib/io/framebuffer/framebuffer_flush.asm"
; void framebuffer_flush(void);

%include "lib/io/framebuffer/framebuffer_mouse_poll.asm"
; void framebuffer_mouse_poll(void);

%include "lib/math/rand/rand_int_array.asm"
; void rand_int_array(long* {rdi}, int {rsi}, uint {rdx}, 
;			signed long {rcx}, signed long {r8});

%include "lib/math/rand/rand_int.asm"
; signed long {rax} rand_int(signed long {rdi}, signed long {rsi});

%include "lib/io/bitmap/set_rect.asm"
; void set_rect(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});

%include "lib/io/bitmap/set_filled_rect.asm"
; void set_filled_rect(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});

%include "lib/io/bitmap/set_foreground.asm"
; void set_foreground(void* {rdi}, void* {rsi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});

%include "lib/mem/memset.asm"
; void memset(void* {rdi}, char {sil}, ulong {rdx});

%include "lib/sys/exit.asm"
; void exit(char {dil});

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INSTRUCTIONS;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; NOTE: NEED TO RUN THIS AS SUDO

START:

	call heap_init
	call framebuffer_init
	call framebuffer_mouse_init

	; turn off cursor
	mov rsi,.hide_cursor
	mov rdx,6
	mov rax,SYS_WRITE	; set {rax} to write syscall
	syscall			; execute write syscall

	; init blue screen
	mov rdi,0x1FF3A6EA5
	call framebuffer_clear

	; grey task bar
	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,0x1FFD4D0C8
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	xor r8d,r8d
	mov r9d,ecx
	sub r9d,30
	mov r10d,edx
	mov r11d,ecx
	call set_filled_rect

	; start box
	mov rsi,0x1FF000000
	xor r8d,r8d
	mov r9d,ecx
	sub r9d,30
	mov r10d,110
	mov r11d,ecx
	dec r11d
	call set_rect

	; windows logo
	mov rsi,0x1FF000000
	mov r8d,2
	mov r9d,ecx
	sub r9d,26
	mov r10d,r8d
	add r10d,25
	mov r11d,r9d
	add r11d,22
	call set_filled_rect

	; red square	
	mov rsi,0x1FFFF0000
	mov r8d,5
	mov r9d,ecx
	sub r9d,24
	mov r10d,r8d
	add r10d,8
	mov r11d,r9d
	add r11d,8
	call set_filled_rect

	; green square	
	mov rsi,0x1FF00FF00
	mov r8d,16
	mov r9d,ecx
	sub r9d,24
	mov r10d,r8d
	add r10d,8
	mov r11d,r9d
	add r11d,8
	call set_filled_rect

	; blue square	
	mov rsi,0x1FF0000FF
	mov r8d,5
	mov r9d,ecx
	sub r9d,14
	mov r10d,r8d
	add r10d,8
	mov r11d,r9d
	add r11d,8
	call set_filled_rect

	; yellow square	
	mov rsi,0x1FFFFFF00
	mov r8d,16
	mov r9d,ecx
	sub r9d,14
	mov r10d,r8d
	add r10d,8
	mov r11d,r9d
	add r11d,8
	call set_filled_rect

	; start text
	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,0x1FF000000
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	mov r8d,30
	mov r9d,ecx
	sub r9d,22
	mov r10d,2
	mov r11,.start_text
	mov r12,SCHIZOFONT	
	call set_text

	; create intermediate buffer for the start menu
	mov rdi,[framebuffer_init.framebuffer_size]
	call heap_alloc
	mov r14,rax	; buffer to combine multiple layers
	
	; actually draw the start menu beforehand (big brain)
	mov rdi,r14
	xor sil,sil
	mov rdx,[framebuffer_init.framebuffer_size]
	call memset

	; start menu grey rectangle
	mov rsi,0x1FFD4D0C8
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	xor r8d,r8d
	mov r9d,ecx
	sub r9d,631
	mov r10d,300
	mov r11d,ecx
	sub r11d,31
	call set_filled_rect
	mov rsi,0x1FF000000
	call set_rect; TODO

	; shut down rectangle
	mov rsi,0x1FF000000
	xor r8d,r8d
	mov r9d,ecx
	sub r9d,631
	mov r10d,300
	mov r11d,r9d
	add r11d,60
	call set_rect; TODO

	; shut down red rectangle
	mov rsi,0x1FFFF0000
	mov r8d,10
	mov r9d,ecx
	sub r9d,621
	mov r10d,50
	mov r11d,r9d
	add r11d,40
	call set_filled_rect

	; shut down text
	mov rsi,0x1FF000000
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]	
	mov r8d,70
	mov r9d,ecx
	sub r9d,611
	mov r10d,3
	mov r11,.shut_down_text
	mov r12,SCHIZOFONT	
	call set_text

	; create intermediate buffer background and taskbar
	mov rdi,[framebuffer_init.framebuffer_size]
	call heap_alloc
	mov r15,rax	; buffer to combine multiple layers

	; copy starting framebuffer intermediate buffer
	mov rdi,r15
	mov rsi,[framebuffer_init.framebuffer_address]
	mov rdx,[framebuffer_init.framebuffer_size]
	call memcopy
	
.loop:
	; flush to screen
	call framebuffer_flush

	; check mouse status	
	call framebuffer_mouse_poll

	; if left click isn't pressed, nothing to draw but cursor
	cmp byte [framebuffer_mouse_init.mouse_state],1
	jne .no_drawing

.left_clicked:

	; if we have clicked on the start menu, but now we clicked somewhere, 
	;	start menu should go away	
	cmp byte [.start_menu_clicked],1
	jne .didnt_click_after_start

	; check if we clicked "shut down"
	cmp dword [framebuffer_mouse_init.mouse_x],300
	jg .not_shut_down_click
	mov eax,[framebuffer_init.framebuffer_height]
	sub eax,571
	cmp dword [framebuffer_mouse_init.mouse_y],eax
	jg .not_shut_down_click
	sub eax,60
	cmp dword [framebuffer_mouse_init.mouse_y],eax
	jl .not_shut_down_click

	; clear screen
	xor rdi,rdi	
	call framebuffer_clear
	call framebuffer_flush

	; shut down
	xor dil,dil
	call exit

.not_shut_down_click:

	xor al,al
	mov byte [.start_menu_clicked],al

.didnt_click_after_start:
		
	cmp dword [framebuffer_mouse_init.mouse_x],110
	jg .not_start_click
	mov eax,[framebuffer_init.framebuffer_height]
	sub eax,30
	cmp dword [framebuffer_mouse_init.mouse_y],eax
	jl .not_start_click

	; we are in the start box	
	mov al,1
	mov byte [.start_menu_clicked],al

.not_start_click:

.no_drawing:

	; first copy background buffer to framebuffer
	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,r15
	mov rdx,[framebuffer_init.framebuffer_size]
	call memcopy

	cmp byte [.start_menu_clicked],1
	jne .dont_render_start_menu

	; copy start menu buffer to framebuffer
	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,r14
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	mov r8d,edx
	mov r9d,ecx
	xor r10d,r10d
	xor r11d,r11d	
	call set_foreground

.dont_render_start_menu:

	; then copy the cursor as foreground onto the framebuffer
	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,.PEPE_BIG
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	mov r8d,26
	mov r9d,14
	mov r10d,[framebuffer_mouse_init.mouse_x]
	mov r11d,[framebuffer_mouse_init.mouse_y]
	call set_foreground

	; flush output to the screen
	call framebuffer_flush
	
jmp .loop

%define G 0xFF2B7544
%define W 0xFFFFFFFF
%define B 0xFF000000
%define T 0x00000000
%define S 0xFF2945E3
%define R 0xFF780016

.PEPE_BIG: ; (26x14)
	dd 0,0,0,0,0,0,G,G,G,G,0,0,G,G,G,G,0,0,0,0,0,0,0,0,0,0
	dd 0,0,0,0,0,0,G,G,G,G,0,0,G,G,G,G,0,0,0,0,0,0,0,0,0,0
	dd 0,0,0,0,G,G,G,G,G,G,G,G,G,G,G,G,G,G,0,0,0,0,0,0,0,0
	dd 0,0,0,0,G,G,G,G,G,G,G,G,G,G,G,G,G,G,0,0,0,0,0,0,0,0
	dd G,G,0,0,G,G,B,B,W,W,W,W,B,B,W,W,G,G,G,G,0,0,0,0,0,0
	dd G,G,0,0,G,G,B,B,W,W,W,W,B,B,W,W,G,G,G,G,0,0,0,0,0,0
	dd 0,0,G,G,0,0,G,G,G,G,G,G,G,G,G,G,G,G,G,G,0,0,0,0,G,G
	dd 0,0,G,G,0,0,G,G,G,G,G,G,G,G,G,G,G,G,G,G,0,0,0,0,G,G
	dd 0,0,0,0,G,G,R,R,R,R,R,R,R,R,G,G,G,G,G,G,G,G,0,0,G,G
	dd 0,0,0,0,G,G,R,R,R,R,R,R,R,R,G,G,G,G,G,G,G,G,0,0,G,G
	dd 0,0,0,0,0,0,S,S,G,G,G,G,G,G,G,G,G,G,G,G,G,G,0,0,G,G
	dd 0,0,0,0,0,0,S,S,G,G,G,G,G,G,G,G,G,G,G,G,G,G,0,0,G,G
	dd 0,0,0,0,0,0,0,0,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,0,0
	dd 0,0,0,0,0,0,0,0,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,S,0,0

.number_buffer:
	db 0,0

.start_text:
	db `Start`,0

.shut_down_text:
	db `Shut Down`,0

.hide_cursor:
	db `\e[?25l`

.start_menu_clicked:
	db 0

END:

PRINT_BUFFER: 	; PRINT_BUFFER_SIZE bytes will be allocated here at runtime,
		; all initialized to zeros

HEAP_START_ADDRESS equ (PRINT_BUFFER+PRINT_BUFFER_SIZE)

