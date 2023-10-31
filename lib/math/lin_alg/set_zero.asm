%ifndef SET_ZERO
%define SET_ZERO

set_zero:
; void set_zero(double* {rdi}, uint {rsi});
; Sets {rsi}x{rsi} matrix at address {rdi} to zeros.

	push rdi
	push rsi
	push rax

	imul rsi,rsi
	xor rax,rax

.loop:
	mov [rdi],rax
	add rdi,8
	dec rsi
	jnz .loop

	pop rax
	pop rsi
	pop rdi

	ret

%endif
