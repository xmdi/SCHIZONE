%ifndef NORMALIZE_3
%define NORMALIZE_3

normalize_3:
; void normalize_3(double* {rdi});
; 	Normalizes the 3x1 double vector starting at {rsi} in-place.

	sub rsp,48
	movdqu [rsp],xmm0
	movdqu [rsp+16],xmm1
	movdqu [rsp+32],xmm2

	; compute vector magnitude
	movsd xmm0,[rdi]
	mulsd xmm0,xmm0
	movsd xmm1,[rdi+8]
	mulsd xmm1,xmm1
	movsd xmm2,[rdi+16]
	mulsd xmm2,xmm2
	addsd xmm0,xmm1
	addsd xmm0,xmm2
	sqrtsd xmm0,xmm2
	movsd xmm1,[.one]
	divsd xmm1,xmm0

	; scale first component
	movsd xmm0,[rdi]
	mulsd xmm0,xmm1
	movsd [rdi],xmm0

	; scale second component
	movsd xmm0,[rdi+8]
	mulsd xmm0,xmm1
	movsd [rdi+8],xmm0

	; scale third component
	movsd xmm0,[rdi+16]
	mulsd xmm0,xmm1
	movsd [rdi+16],xmm0

	movdqu xmm0,[rsp]
	movdqu xmm1,[rsp+16]
	movdqu xmm2,[rsp+32]
	add rsp,48

	ret			; return

.one:
	dq 1.0

%endif
