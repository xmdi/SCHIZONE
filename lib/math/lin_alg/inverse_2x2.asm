%ifndef INVERSE_2x2
%define INVERSE_2x2

inverse_2x2:
; void inverse_2x2(double* {rdi}, double* {rsi});
; Inverts the 2x2 matrix of double at address {rsi} into the 2x2 matrix at address {rdi}.

	; save registers
	sub rsp,32
	movdqu [rsp+0],xmm0
	movdqu [rsp+16],xmm1
	
	; compute determinant
	movsd xmm0,[rsi]
	mulsd xmm0,[rsi+24]
	movsd xmm1,[rsi+8]
	mulsd xmm1,[rsi+16]
	subsd xmm0,xmm1
	movsd xmm1,[.one]
	divsd xmm1,xmm0		; {xmm1} contains 1/determinant

	; element 1,1
	movsd xmm0,[rsi+24]
	mulsd xmm0,xmm1
	movsd [rdi],xmm0

	; element 1,2
	pxor xmm0,xmm0
	subsd xmm0,[rsi+8]
	mulsd xmm0,xmm1
	movsd [rdi+8],xmm0

	; element 2,1
	pxor xmm0,xmm0
	subsd xmm0,[rsi+16]
	mulsd xmm0,xmm1
	movsd [rdi+16],xmm0

	; element 2,2
	movsd xmm0,[rsi+24]
	mulsd xmm0,xmm1
	movsd [rdi+24],xmm0

	; restore registers
	movdqu xmm0,[rsp+0]
	movdqu xmm1,[rsp+16]
	add rsp,32
	
	ret

.one:
	dq 1.0

%endif
