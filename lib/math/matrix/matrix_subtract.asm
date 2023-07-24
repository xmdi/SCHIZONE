%ifndef MATRIX_SUBTRACT
%define MATRIX_SUBTRACT

matrix_subtract:
; void matrix_subtract(double* {rdi}, double* {rsi}, double* {rdx}, uint {rcx});
; 	Subtracts {rcx} elements of the double-precision floating point
;	matrix beginning at {rdx} from the one starting at {rsi} and places the
;	result in the matrix beginning at {rdi}.

	push rdi
	push rsi
	push rdx
	push rcx
	sub rsp,16
	movdqu [rsp],xmm0

.loop:				; loop over {rcx} elements
	movsd xmm0,[rsi]	; grab element from first matrix
	subsd xmm0,[rdx]	; subtract element from the second matrix
	movsd [rdi],xmm0	; save the result in the destination matrix
	add rsi,8		; go onto next element
	add rdi,8
	add rdx,8
	dec rcx
	jnz .loop		; loop until finished

	movdqu xmm0,[rsp]
	add rsp,16
	pop rcx
	pop rdx
	pop rsi
	pop rdi

	ret			; return

%endif
