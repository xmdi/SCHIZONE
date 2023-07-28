%ifndef MATRIX_SUBTRACT_IN_PLACE
%define MATRIX_SUBTRACT_IN_PLACE

matrix_subtract_in_place:
; void matrix_subtract_in_place(double* {rdi}, double* {rsi}, long {rdx});
; 	Subtracts {rdx} elements of the double-precision floating point
;	matrix beginning at {rsi} from the one starting at {rdi}.

	push rdi
	push rsi
	push rdx
	sub rsp,16
	movdqu [rsp],xmm0

.loop:				; loop over {rdx} elements
	movsd xmm0,[rdi]	; grab element from first matrix
	subsd xmm0,[rsi]	; subtract off element from second matrix
	movsd [rdi],xmm0	; move it to the first matrix
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
