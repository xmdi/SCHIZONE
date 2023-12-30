%ifndef CROSS_PRODUCT_3
%define CROSS_PRODUCT_3

cross_product_3:
; void cross_product_3(double* {rdi}, double* {rsi}, double* {rdx});
; 	Computes the cross product of two 3x1 vectors starting at addresses
;	{rsi} and {rdx} and places the result starting at address {rdi}.

	sub rsp,64
	movdqu [rsp+0],xmm0
	movdqu [rsp+16],xmm1
	movdqu [rsp+32],xmm2
	movdqu [rsp+48],xmm3

	movsd xmm0,[rsi+8]
	mulsd xmm0,[rdx+16]
	movsd xmm1,[rsi+16]
	mulsd xmm1,[rdx+8]
	subsd xmm0,xmm1
	movsd xmm2,xmm0

	movsd xmm0,[rsi+16]
	mulsd xmm0,[rdx+0]
	movsd xmm1,[rsi+0]
	mulsd xmm1,[rdx+16]
	subsd xmm0,xmm1
	movsd xmm3,xmm0

	movsd xmm0,[rsi+0]
	mulsd xmm0,[rdx+8]
	movsd xmm1,[rsi+8]
	mulsd xmm1,[rdx+0]
	subsd xmm0,xmm1

	movsd [rdi+0],xmm2
	movsd [rdi+8],xmm3
	movsd [rdi+16],xmm0

	movdqu xmm0,[rsp+0]
	movdqu xmm1,[rsp+16]
	movdqu xmm2,[rsp+32]
	movdqu xmm3,[rsp+48]
	add rsp,64

	ret			; return

%endif
