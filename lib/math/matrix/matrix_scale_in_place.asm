%ifndef MATRIX_SCALE_IN_PLACE
%define MATRIX_SCALE_IN_PLACE

matrix_scale_in_place:
; void matrix_scale_in_place(double* {rdi}, long {rsi}, double {xmm0});
; 	Scales {rsi} elements of the double-precision floating point
;	matrix beginning at {rdi} by the low 8-byte scalar in {xmm0}.

	push rdi
	push rsi

.loop:				; loop over {rsi} elements
	mulsd [rdi],xmm0	; scale element by {xmm0}
	add rdi,8
	dec rsi
	jnz .loop		; loop until finished

	pop rsi
	pop rdi

	ret			; return

%endif
