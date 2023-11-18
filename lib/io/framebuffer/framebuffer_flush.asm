%ifndef FRAMEBUFFER_FLUSH
%define FRAMEBUFFER_FLUSH

%include "lib/io/framebuffer/framebuffer_init.asm"

framebuffer_flush:
; void framebuffer_flush(void);
; Immediately flushes the content of the current frame to the screen.

	push rdi
	push rsi
	push rdx
	push rax

	; write frame to framebuffer
	mov rax,SYS_WRITE
	movzx rdi,byte [framebuffer_init.framebuffer_file_descriptor]
	mov rsi,[framebuffer_init.framebuffer_address]
	mov rdx,[framebuffer_init.framebuffer_size]
	syscall
	
	; go back to top of the framebuffer
	mov rax,SYS_LSEEK
	movzx rdi,byte [framebuffer_init.framebuffer_file_descriptor]
	xor rsi,rsi
	mov rdx,SYS_SEEK_SET
	syscall

	pop rax
	pop rdx
	pop rsi
	pop rdi

	ret

%endif
