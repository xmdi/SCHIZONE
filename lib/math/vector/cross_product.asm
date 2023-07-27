%ifndef CROSS_PRODUCT
%define CROSS_PRODUCT

;TODO

cross_product:
; void cross_product(double* {rdi}, double* {rsi}, double* {rdx}, uint {rcx});
; 	Computes the cross product of two {rcx}x1 vectors starting at addresses
;	{rsi} and {rdx} and places the result starting at address {rdi}.

	push rdi
	push rsi
	push rdx
	sub rsp,16
	movdqu [rsp],xmm1

	pxor xmm0,xmm0		; initialize running sum to zero

.loop:				; loop over {rdx} elements, one by one :(
	movsd xmm1,[rsi]	; grab element from second matrix
	mulsd xmm1,[rdi]	; multiply by element from first matrix
	addsd xmm0,xmm1		; add it to the running sum
	add rsi,8		; go onto next element
	add rdi,8
	dec rdx
	jnz .loop		; loop until finished

	movdqu xmm1,[rsp]
	add rsp,16	
	pop rdx
	pop rsi
	pop rdi

	ret			; return

%endif
