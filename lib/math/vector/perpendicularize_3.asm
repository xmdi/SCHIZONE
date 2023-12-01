%ifndef PERPENDICULARIZE_3
%define PERPENDICULARIZE_3

perpendicularize_3:
; void perpendicularize_3(double* {rdi}, double* {rsi});
; 	Makes the 3x1 double vector starting at {rdi} perpendicular to
;	the 3x1 double vector starting at {rsi} (in-place).

	sub rsp,64
	movdqu [rsp],xmm0
	movdqu [rsp+16],xmm1
	movdqu [rsp+32],xmm2
	movdqu [rsp+32],xmm2
	movdqu [rsp+48],xmm3

	movsd xmm0,[rsi+0]
	mulsd xmm0,[rdi+0]
	movsd xmm1,[rsi+8]
	mulsd xmm1,[rdi+8]
	movsd xmm2,[rsi+16]
	mulsd xmm2,[rdi+16]
	addsd xmm0,xmm1
	addsd xmm0,xmm2	
	movsd xmm3,xmm0		; {xmm3} = U dot V

	movsd xmm0,[rsi+0]
	mulsd xmm0,xmm0
	movsd xmm1,[rsi+8]
	mulsd xmm1,xmm1
	movsd xmm2,[rsi+16]
	mulsd xmm2,xmm2
	addsd xmm0,xmm1
	addsd xmm0,xmm2		; {xmm0} = V dot V

	divsd xmm3,xmm0		; {xmm3} = (U dot V) / (V dot V)

	; U = U - [(U dot V) / (V dot V)] * V
	movsd xmm0,[rsi+0]
	movsd xmm1,[rsi+8]
	movsd xmm2,[rsi+16]
	mulsd xmm0,xmm3
	mulsd xmm1,xmm3
	mulsd xmm2,xmm3
	movsd xmm3,[rdi+0]
	subsd xmm3,xmm0
	movsd [rdi+0],xmm3
	movsd xmm3,[rdi+8]
	subsd xmm3,xmm1
	movsd [rdi+8],xmm3
	movsd xmm3,[rdi+16]
	subsd xmm3,xmm2
	movsd [rdi+16],xmm3

	movdqu xmm0,[rsp]
	movdqu xmm1,[rsp+16]
	movdqu xmm2,[rsp+32]
	movdqu xmm3,[rsp+48]
	add rsp,64

	ret			; return

%endif
