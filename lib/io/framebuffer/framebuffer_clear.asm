%ifndef FRAMEBUFFER_CLEAR
%define FRAMEBUFFER_CLEAR

%include "lib/io/framebuffer/framebuffer_init.asm"

framebuffer_clear:
; void framebuffer_clear(uint {rdi});
; Sets the entire frame to the 32-bit ARGB color defined in {rdi}.

	push rsi
	push rcx

	; loop thru all pixels in framebuffer and set color
	mov rcx,[framebuffer_init.framebuffer_size]
	shr rcx,2
	mov rsi,[framebuffer_init.framebuffer_address]

.loop:
	mov dword [rsi],edi
	add rsi,4
	dec rcx
	jnz .loop

.end:
	pop rcx
	pop rsi

	ret

%endif
