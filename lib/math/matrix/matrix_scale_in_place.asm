%ifndef MATRIX_SCALE_IN_PLACE
%define MATRIX_SCALE_IN_PLACE

matrix_scale_in_place:
; void matrix_scale_in_place(double* {rdi}, long {rsi}, double {xmm0});
; 	Scales {rsi} elements of the double-precision floating point
;	matrix beginning at {rdi} by the low 8-byte scalar in {xmm0}.

	push rdi
	push rsi
	sub rsp,16
	movdqu [rsp],xmm1

.loop:				; loop over {rsi} elements
	movsd xmm1,[rdi]	; grab element from matrix
	mulsd xmm1,xmm0		; scale element by {xmm0}
	movsd [rdi],xmm1	; drop in back in the matrix
	add rdi,8
	dec rsi
	jnz .loop		; loop until finished

	movdqu xmm1,[rsp]
	add rsp,16
	pop rsi
	pop rdi

	ret			; return

%endif
