%ifndef DISTANCE_3
%define DISTANCE_3

distance_3:
; double {xmm0} distance_3(double* {rdi}, double* {rsi});
; 	Returns distance between two 3x1 positions starting at addresses
;	{rdi} and {rsx}.

	sub rsp,32
	movdqu [rsp+0],xmm1
	movdqu [rsp+16],xmm2
	
	; x-component
	movsd xmm0,[rdi+0]
	subsd xmm0,[rsi+0]
	mulsd xmm0,xmm0
	
	; y-component
	movsd xmm1,[rdi+8]
	subsd xmm1,[rsi+8]
	mulsd xmm1,xmm1
	
	; z-component
	movsd xmm2,[rdi+16]
	subsd xmm2,[rsi+16]
	mulsd xmm2,xmm2
	
	; compute distance
	addsd xmm0,xmm1
	addsd xmm0,xmm2
	sqrtsd xmm0,xmm0

	movdqu xmm1,[rsp+0]
	movdqu xmm2,[rsp+16]
	add rsp,32

	ret			; return

%endif
