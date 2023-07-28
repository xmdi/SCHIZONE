%ifndef MATRIX_INSERT_ROW
%define MATRIX_INSERT_ROW

matrix_insert_row:
; void matrix_insert_row(double* {rdi}, double* {rsi}, uint {rdx}, uint {rcx});
; 	Inserts a 1x{rdx} double-precision floating point vector at {rsi} into 
;	row {rcx} of {ANY}x{rdx} matrix starting at address {rdi}.

;	NOTE: should work on matrices of any 8-byte datatype.

	push rdi
	push rsi
	push rdx
	push rcx
	push rax

	shl rcx,3
	imul rcx,rdx	; adjust {rdi} to point to the intended row
	add rdi,rcx	; of the destination matrix

.loop:
	mov rax,[rsi]	; grab source element
	mov [rdi],rax	; drop into destination element

	add rsi,8	; go to next element of source vector
	add rdi,8	; go to next element of destination matrix

	dec rdx		; loop until out of columns
	jnz .loop

	pop rax
	pop rcx
	pop rdx
	pop rsi
	pop rdi

	ret			; return

%endif
