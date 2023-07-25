%ifndef MATRIX_MULTIPLY
%define MATRIX_MULTIPLY

matrix_multiply:
; void matrix_multiply(double* {rdi}, double* {rsi}, double* {rdx}, uint {rcx}
;	uint {r8}, uint {r9});
; 	Multiplies a {rcx}x{r8} matrix at {rsi} by a {r8}x{r9} matrix at {rdx}
;	and places the result in the {rcx}x{r9} matrix beginning at {rdi}.
	
	; register usage:

	; {rdi}=address of current element in result matrix
	; {rsi}=address of current row in matrix 1
	; {rdx}=address of first element in matrix 2
	; {rcx}=dimension of rows of result matrix
	; {r8} =dimension of cols of result matrix (converted to bytes)
	; {r9} =inner dimension (converted to bytes)

	; {r10}=workspace for integer math
	; {r11}=(k*cols) to track row of matrix 2
	; {r12}=current col count, j, (in bytes)
	; {r13}=current inner dimension counter, k (in bytes)
	; {xmm0}=workspace for floating point math
	; {xmm1}=track sum of inner dot products

	; save registers
	push rdi
	push rsi
	push rdx
	push rcx
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	sub rsp,32
	movdqu [rsp+16],xmm1
	movdqu [rsp],xmm0

	shl r8,3	; {r8}=cols of result * 8
	shl r9,3	; {r9}=inner dimension * 8

.loop_rows:		; loop over rows of result
	xor r12,r12	; initialize j=0 (will be incremented by 8)

.loop_cols:		; loop over cols of result
	xor r13,r13	; initialize k=0 (will be incremented by 8)
	xor r11,r11	; initialize k*cols of result to 0
	pxor xmm1,xmm1	; track running sum in {xmm1}

.loop_inner:
	movsd xmm0,[rsi+r13]	; move matrix 1 element into {xmm0}
	mov r10,r11		; compute offset into matrix 2
	add r10,r12
	mulsd xmm0,[rdx+r10]	; multiply 2 matrix elements
	addsd xmm1,xmm0		; add to running sum

	add r11,r8		; increment k*cols by cols
	add r13,8		; increment k
	cmp r13,r9		; loop until we completed the inner dot product
	jb .loop_inner

	movsd [rdi],xmm1	; move sum to result matrix
	add rdi,8		; increment address of result matrix
	add r12,8		; increment j
	cmp r12,r8		; loop until we completed last column
	jb .loop_cols

	add rsi,r9		; increment address of matrix 1
	dec rcx			; loop until we completed last row
	jnz .loop_rows
	
	; restore registers
	movdqu xmm1,[rsp+16]
	movdqu xmm0,[rsp]
	add rsp,32
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rcx
	pop rdx
	pop rsi
	pop rdi

	ret			; return

%endif
