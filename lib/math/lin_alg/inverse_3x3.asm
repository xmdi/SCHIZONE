%ifndef INVERSE_3x3
%define INVERSE_3x3

inverse_3x3:
; void inverse_3x3(double* {rdi}, double* {rsi});
; Inverts the 3x3 matrix of double at address {rsi} into the 3x3 matrix at address {rdi}.

	; save registers
	sub rsp,48
	movdqu [rsp+0],xmm0
	movdqu [rsp+16],xmm1
	movdqu [rsp+32],xmm2
	
	; compute determinant
	movsd xmm1,[rsi+32]
	mulsd xmm1,[rsi+64]
	movsd xmm2,[rsi+40]
	mulsd xmm2,[rsi+56]
	subsd xmm1,xmm2
	mulsd xmm1,[rsi+0]
	movsd xmm0,xmm1

	movsd xmm1,[rsi+24]
	mulsd xmm1,[rsi+64]
	movsd xmm2,[rsi+40]
	mulsd xmm2,[rsi+48]
	subsd xmm1,xmm2
	mulsd xmm1,[rsi+8]
	subsd xmm0,xmm1

	movsd xmm1,[rsi+24]
	mulsd xmm1,[rsi+56]
	movsd xmm2,[rsi+32]
	mulsd xmm2,[rsi+48]
	subsd xmm1,xmm2
	mulsd xmm1,[rsi+16]
	addsd xmm1,xmm0
	
	movsd xmm0,[.one]
	divsd xmm0,xmm1		; {xmm0} contains 1/det


	; element 1,1
	movsd xmm1,[rsi+32]
	mulsd xmm1,		



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
	movsd xmm0,[rsi]
	mulsd xmm0,xmm1
	movsd [rdi+24],xmm0

	; restore registers
	movdqu xmm0,[rsp+0]
	movdqu xmm1,[rsp+16]
	movdqu xmm2,[rsp+32]
	add rsp,48
	
	ret

.one:
	dq 1.0

%endif
