%ifndef SET_IDENTITY
%define SET_IDENTITY

%include "lib/math/lin_alg/set_zero.asm"

set_identity:
; void set_identity(double* {rdi}, uint {rsi});
; Sets {rsi}x{rsi} matrix at address {rdi} to identity.

	call set_zero

	push rdi
	push rsi
	push rax
	push rcx

	mov rcx,rsi
	shl rsi,3
	add rsi,8
	mov rax,[.one]

.loop:
	mov [rdi],rax
	add rdi,rsi
	dec rcx
	jnz .loop

	pop rcx
	pop rax
	pop rsi
	pop rdi

	ret

.one:
	dq 1.0

%endif
