%ifndef MATRIX_ADD_IN_PLACE
%define MATRIX_ADD_IN_PLACE

matrix_add_in_place:
; void matrix_add_in_place(double* {rdi}, double* {rsi}, long {rdx});
; 	Adds {rdx} elements of the double-precision floating point
;	matrix beginning at {rsi} to the one starting at {rdi}.

	push rdi
	push rsi
	push rdx
	sub rsp,16
	movdqu [rsp],xmm0

.loop:				; loop over {rdx} elements
	movsd xmm0,[rsi]	; grab element from second matrix
	addsd [rdi],xmm0	; add it to the first matrix
	add rsi,8		; go onto next element
	add rdi,8
	dec rdx
	jnz .loop		; loop until finished

	movdqu xmm0,[rsp]
	add rsp,16	
	pop rdx
	pop rsi
	pop rdi

	ret			; return

%endif
