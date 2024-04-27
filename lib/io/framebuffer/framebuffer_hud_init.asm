%ifndef FRAMEBUFFER_HUD_INIT
%define FRAMEBUFFER_HUD_INIT

%include "lib/mem/heap_alloc.asm"
%include "lib/io/framebuffer/framebuffer_init.asm"

framebuffer_hud_init:
; void* {rax} framebuffer_hud_init(void);
; Initializes an intermediate buffer for the hud to be rendered to. 
; Automatically pulls relevant details from framebuffer.
; Returns address to hudbuffer (null on error).
	
	push rdi

	mov rdi,[framebuffer_init.framebuffer_size]
	call heap_alloc
	mov [.hudbuffer_address],rax	; save hudbuffer address

	pop rdi

	ret

.hudbuffer_address:
	dq 0

.hud_enabled:
	db 0
.hud:
.hud_head:
	dq 0
.hud_tail:
	dq 0

%if 0 ; TO ENABLE HUD

	mov al,1
	mov [framebuffer_hud_init.hud_enabled],al

	mov rax,.HUD_STARTING_ELEMENT
	mov [framebuffer_hud_init.hud_head],rax

	mov rax,.HUD_ENDING_ELEMENT
	mov [framebuffer_hud_init.hud_tail],rax

%endif

%endif
