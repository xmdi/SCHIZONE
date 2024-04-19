%ifndef DOT_PRODUCT_3
%define DOT_PRODUCT_3

dot_product_3:
; double {xmm0} dot_product_3(double* {rdi}, double* {rsi});
; 	Computes the dot product of two 3x1 vectors starting at addresses
;	{rdi} and {rsi}.

	sub rsp,32
	movdqu [rsp+0],xmm1
	movdqu [rsp+16],xmm2

	; first component into the dot product
	movsd xmm0,[rdi]	; first element of vector 1
	mulsd xmm0,[rsi]	; first element of vector 2

	; second component into the dot product
	movsd xmm1,[rdi+8]	; second element of vector 1
	mulsd xmm1,[rsi+8]	; second element of vector 2
	
	; third component into the dot product
	movsd xmm2,[rdi+16]	; third element of vector 1
	mulsd xmm2,[rsi+16]	; third element of vector 2
	
	; add everything together
	addsd xmm1,xmm2		; add second and third dots together
	addsd xmm0,xmm1		; sum everything into {xmm0}

	movdqu xmm1,[rsp+0]
	movdqu xmm2,[rsp+16]
	add rsp,32

	ret			; return

%endif
