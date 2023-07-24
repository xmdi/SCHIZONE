%ifndef MATRIX_ADD
%define MATRIX_ADD

matrix_add:
; void matrix_add(double* {rdi}, double* {rsi}, double* {rdx}, uint {rcx});
; 	Adds {rcx} elements of the double-precision floating point
;	matrix beginning at {rsi} to the one starting at {rdx} and places the
;	result in the matrix beginning at {rdi}.

	push rdi
	push rsi
	push rdx
	push rcx
	sub rsp,16
	movdqu [rsp],xmm0

.loop:				; loop over {rcx} elements
	movsd xmm0,[rdx]	; grab element from second matrix
	addsd xmm0,[rsi]	; add it to the first matrix
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
