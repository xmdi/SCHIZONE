%ifndef MATRIX_EXTRACT_ROW
%define MATRIX_EXTRACT_ROW

matrix_extract_row:
; void matrix_extract_row(double* {rdi}, double* {rsi}, uint {rdx}, uint {rcx});
; 	Extracts row {rcx} of {ANY}x{rdx} double-precision floating point matrix
; 	starting at {rsi} into 1x{rdx} vector at address {rdi}.

;	NOTE: should work on matrices of any 8-byte datatype.

	push rdi
	push rsi
	push rdx
	push rcx
	push rax

	shl rcx,3
	imul rcx,rdx	; adjust {rdi} to point to the intended row
	add rsi,rcx	; of the source matrix

.loop:
	movq rax,[rsi]	; grab source element
	movq [rdi],rax	; drop into destination element

	add rsi,8	; go to next element of source matrix
	add rdi,8	; go to next element of destination vector

	dec rdx		; loop until out of columns
	jnz .loop

	pop rax
	pop rcx
	pop rdx
	pop rsi
	pop rdi

	ret			; return

%endif
