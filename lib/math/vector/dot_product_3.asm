%ifndef DOT_PRODUCT_3
%define DOT_PRODUCT_3

dot_product_3:
; double {xmm0} dot_product_3(double* {rdi}, double* {rsi});
; 	Computes the dot product of two 3x1 vectors starting at addresses
;	{rdi} and {rsi}.

;	NOTE: this algorithm uses an SSE3 instruction: haddpd.

	sub rsp,16
	movdqu [rsp],xmm1

	; first component into the dot product
	movsd xmm0,[rdi]	; first element of vector 1
	mulsd xmm0,[rsi]	; first element of vector 2

	; second and third components into the dot product
	movapd xmm1,[rdi+8]	; second and third element of vector 1
	mulpd xmm1,[rsi+8]	; second and third element of vector 2
	
	; add everything together
	haddpd xmm1,xmm1	; add second and third dots together
	addsd xmm0,xmm1		; sum everything into {xmm0}

	movdqu xmm1,[rsp]
	add rsp,16

	ret			; return

%endif
