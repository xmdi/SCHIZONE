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
	mulsd xmm1,[rsi+64]
	movsd xmm2,[rsi+40]
	mulsd xmm2,[rsi+56]
	subsd xmm1,xmm2
	mulsd xmm1,xmm0
	movsd [rdi+0],xmm1		

	; element 1,2
	movsd xmm1,[rsi+16]
	mulsd xmm1,[rsi+56]
	movsd xmm2,[rsi+8]
	mulsd xmm2,[rsi+64]
	subsd xmm1,xmm2
	mulsd xmm1,xmm0
	movsd [rdi+8],xmm1		

	; element 1,3
	movsd xmm1,[rsi+8]
	mulsd xmm1,[rsi+40]
	movsd xmm2,[rsi+16]
	mulsd xmm2,[rsi+32]
	subsd xmm1,xmm2
	mulsd xmm1,xmm0
	movsd [rdi+16],xmm1		

	; element 2,1
	movsd xmm1,[rsi+40]
	mulsd xmm1,[rsi+48]
	movsd xmm2,[rsi+24]
	mulsd xmm2,[rsi+64]
	subsd xmm1,xmm2
	mulsd xmm1,xmm0
	movsd [rdi+24],xmm1		

	; element 2,2
	movsd xmm1,[rsi+0]
	mulsd xmm1,[rsi+64]
	movsd xmm2,[rsi+16]
	mulsd xmm2,[rsi+48]
	subsd xmm1,xmm2
	mulsd xmm1,xmm0
	movsd [rdi+32],xmm1		

	; element 2,3
	movsd xmm1,[rsi+16]
	mulsd xmm1,[rsi+24]
	movsd xmm2,[rsi+0]
	mulsd xmm2,[rsi+40]
	subsd xmm1,xmm2
	mulsd xmm1,xmm0
	movsd [rdi+40],xmm1		

	; element 3,1
	movsd xmm1,[rsi+24]
	mulsd xmm1,[rsi+56]
	movsd xmm2,[rsi+32]
	mulsd xmm2,[rsi+48]
	subsd xmm1,xmm2
	mulsd xmm1,xmm0
	movsd [rdi+48],xmm1		

	; element 3,2
	movsd xmm1,[rsi+8]
	mulsd xmm1,[rsi+48]
	movsd xmm2,[rsi+0]
	mulsd xmm2,[rsi+56]
	subsd xmm1,xmm2
	mulsd xmm1,xmm0
	movsd [rdi+56],xmm1		

	; element 3,3
	movsd xmm1,[rsi+0]
	mulsd xmm1,[rsi+32]
	movsd xmm2,[rsi+8]
	mulsd xmm2,[rsi+24]
	subsd xmm1,xmm2
	mulsd xmm1,xmm0
	movsd [rdi+64],xmm1		

	; restore registers
	movdqu xmm0,[rsp+0]
	movdqu xmm1,[rsp+16]
	movdqu xmm2,[rsp+32]
	add rsp,48
	
	ret

.one:
	dq 1.0

%endif
