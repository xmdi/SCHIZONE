%ifndef FRAMEBUFFER_MOUSE_POLL
%define FRAMEBUFFER_MOUSE_POLL

%include "lib/io/framebuffer/framebuffer_mouse_init.asm"
%include "lib/io/framebuffer/framebuffer_init.asm"

framebuffer_mouse_poll:
; void framebuffer_mouse_poll(void);
; Polls mouse device file for updates to data structures in 
; framebuffer_mouse_init.asm.
; No error handling.
	
	push rdi
	push rsi
	push rdx
	push rax

	mov rax,SYS_READ
	mov dil,[framebuffer_mouse_init.file_descriptor]
	mov rsi,.buffer
	mov rdx,4
	syscall

	test rax,rax
	js .ret

	; mouse state
	mov esi,[.buffer]

	and esi,0x7
	mov [framebuffer_mouse_init.mouse_state],sil

	; dx
	mov esi,[.buffer]
	shr esi,8
	and esi,0xff

	cmp rsi,127
	jle .no_adjust_x
	sub rsi,256
.no_adjust_x:
	add [framebuffer_mouse_init.mouse_x],esi
	mov esi,[framebuffer_init.framebuffer_width]
	cmp [framebuffer_mouse_init.mouse_x],esi
	jl .within_upper_limit_x
	mov [framebuffer_mouse_init.mouse_x],esi
.within_upper_limit_x:
	xor esi,esi
	cmp [framebuffer_mouse_init.mouse_x],esi
	jge .within_lower_limit_x
	mov [framebuffer_mouse_init.mouse_x],esi
.within_lower_limit_x:

	; dy
	mov esi,[.buffer]
	shr esi,16
	and esi,0xff

	cmp rsi,127
	jle .no_adjust_y
	sub rsi,256
.no_adjust_y:
	sub [framebuffer_mouse_init.mouse_y],esi
	mov esi,[framebuffer_init.framebuffer_height]
	cmp [framebuffer_mouse_init.mouse_y],esi
	jl .within_upper_limit_y
	mov [framebuffer_mouse_init.mouse_y],esi
.within_upper_limit_y:
	xor esi,esi
	cmp [framebuffer_mouse_init.mouse_y],esi
	jge .ret
	mov [framebuffer_mouse_init.mouse_y],esi

.ret:

	pop rax
	pop rdx
	pop rsi
	pop rdi

	ret

.buffer:
	dd 0

%endif
