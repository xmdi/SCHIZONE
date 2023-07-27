%ifndef MATRIX_POPULATE
%define MATRIX_POPULATE

matrix_populate:
; void matrix_populate(double* {rdi}, double* {rsi}, uint {rdx}, uint {rcx},
;			 uint {r8}, uint {r9});
; 	Populates a {rdx}x{rcx} double-precision floating point matrix
;	beginning at address {rdi} with data beginning at address {rsi}, 
;	with {r8} bytes between rows of elements and {r9} bytes between
;	columns of elements.

;	NOTE: this function would work on matrices of any 8-byte datatype.

	push rax
	push rdi
	push rsi
	push rdx
	push rcx

	shl rcx,3	; convert columns to bytewidth of matrix rows

.loop_rows:
			; {rsi} points to the current row of the source matrix
	xor r10,r10	; {r10} contains offset to column in source matrix

.loop_cols:		; one element at a time
	mov rax,[rsi+r10]	; grab element from source matrix
	mov [rdi],rax		; drop element in destination matrix
	
	add rdi,8	; move to next element of the destination matrix
	add r10,r9	; increment offset by column "width" 
	
	cmp r10,rcx	; loop until out of columns
	jb .loop_cols

	add rsi,r8	; move to next row of source matrix
	dec rdx		; loop until out of rows
	jnz .loop_rows

	pop rcx
	pop rdx
	pop rsi
	pop rdi
	pop rax

	ret			; return

%endif
