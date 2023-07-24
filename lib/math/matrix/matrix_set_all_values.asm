%ifndef MATRIX_SET_ALL_VALUES
%define MATRIX_SET_ALL_VALUES

matrix_set_all_values:
; void matrix_set_all_values(double* {rdi}, uint {rsi}, double {xmm0});
; 	Sets {rsi} elements of the double-precision floating point
;	matrix beginning at {rdi} to the low 8-byte double in {xmm0}.

	push rdi
	push rsi

.loop:				; loop over {rsi} elements
	movsd [rdi],xmm0	; set one value at a time (should be improved)
	add rdi,8
	dec rsi
	jnz .loop		; loop until finished
	
	pop rsi
	pop rdi

	ret			; return

%endif
