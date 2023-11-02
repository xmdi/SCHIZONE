%ifndef SWAP_MATRIX_ROWS
%define SWAP_MATRIX_ROWS

swap_matrix_rows:
; void swap_matrix_rows(double* {rdi}, double* {rsi}, uint {rdx});
; Swaps {rdx} double elements starting at {rsi} with those at {rdi}.

	push rdi
	push rsi
	push rdx
	sub rsp,32
	movdqu [rsp+0],xmm0
	movdqu [rsp+16],xmm1

.loop:	; could definitely do this more efficiently 
	; instead of one double at a time, but yolo

	movsd xmm0,[rsi]
	movsd xmm1,[rdi]
	movsd [rdi],xmm0
	movsd [rsi],xmm1

	add rdi,8
	add rsi,8
	dec rdx
	jnz .loop

	movdqu xmm0,[rsp+0]
	movdqu xmm1,[rsp+16]
	add rsp,32
	pop rdx
	pop rsi
	pop rdi

	ret

%endif
