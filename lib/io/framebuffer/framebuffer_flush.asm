%ifndef FRAMEBUFFER_FLUSH
%define FRAMEBUFFER_FLUSH

%include "lib/io/framebuffer/framebuffer_init.asm"

framebuffer_flush:
; void framebuffer_flush(void);
; Immediately flushes the content of the current framebuffer to the screen.

	push rdi
	push rsi
	push rdx
	push rax

	mov rax,SYS_WRITE
	mov rdi,framebuffer_init.framebuffer_file_descriptor
	mov rsi,framebuffer_init.framebuffer_address
	mov rdx,framebuffer_init.framebuffer_size
	syscall
	
	pop rax
	pop rdx
	pop rsi
	pop rdi

	ret

.filename:
	db `/dev/fb0\0` 

.framebuffer_file_descriptor:
	db 0

.framebuffer_size:
	dq 0

.screen_info_address:
	dq 0

.framebuffer_address:
	dq 0

%endif
