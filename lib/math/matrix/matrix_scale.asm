%ifndef MATRIX_SCALE
%define MATRIX_SCALE

matrix_scale:
; void matrix_scale(double* {rdi}, double* {rsi}, uint {rdx}, double {xmm0});
; 	Scales {rdx} elements of the double-precision floating point
;	matrix beginning at {rsi} by the low 8-byte scalar in {xmm0} and
;	places the result in the matrix beginning at {rdi}.

	push rdi
	push rsi
	push rdx
	sub rsp,16
	movdqu [rsp],xmm1

.loop:				; loop over {rdx} elements
	movsd xmm1,[rsi]	; grab element from source matrix
	mulsd xmm1,xmm0		; scale it
	movsd [rdi],xmm1	; save the result in the destination matrix
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
