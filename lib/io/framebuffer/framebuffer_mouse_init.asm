%ifndef FRAMEBUFFER_MOUSE_INIT
%define FRAMEBUFFER_MOUSE_INIT

%include "lib/io/file_open.asm"
%include "lib/io/framebuffer/framebuffer_init.asm"

framebuffer_mouse_init:
; void framebuffer_mouse_init(void);
; Initializes data structures to track the current mouse position and
; state. Requires that the "framebuffer" already be in use.
; No error handling.
	
	push rdi
	push rsi
	push rdx
	push rax

	mov rdi,.filename
	mov rsi,SYS_READ_WRITE
	mov rdx,SYS_DEFAULT_PERMISSIONS
	call file_open
	mov [.file_descriptor],al	; save file descriptor	

	pop rax
	pop rdx
	pop rsi
	pop rdi

	ret

.filename:
	db `/dev/input/mice\0` 

.file_descriptor:
	db 0

.mouse_x:	; from left
	dd 0

.mouse_y:	; from top
	dd 0

.mouse_state: ; bit 0 = left, 1 = right, 2 = middle
	db 0

%endif
