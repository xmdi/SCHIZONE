%ifndef MATRIX_EXTRACT_COLUMN
%define MATRIX_EXTRACT_COLUMN

matrix_extract_column:
; void matrix_extract_column(double* {rdi}, double* {rsi}, uint {rdx}, 
;		uint {rcx}, uint {r8});
; 	Extracts a {rdx}x1 double-precision floating point vector at {rdi}
;	from column {r8} of {rdx}x{rcx} matrix starting at address {rsi}.

;	NOTE: should work on matrices of any 8-byte datatype.

	push rdi
	push rsi
	push rdx
	push rcx
	push rax
	push r8

	shl r8,3	; convert target column into byte offset
	add rsi,r8	; adjust {rsi} to column offset {r8}
	
	shl rcx,3	; adjust {rcx} to indicate byte-width of matrix

.loop:
	mov rax,[rsi]	; grab source element
	mov [rdi],rax	; drop into destination element

	add rsi,rcx	; go to next element of source matrix
	add rdi,8	; go to next element of destination vector

	dec rdx		; loop until out of rows
	jnz .loop

	pop r8
	pop rax
	pop rcx
	pop rdx
	pop rsi
	pop rdi

	ret			; return

%endif
