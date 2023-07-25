%ifndef MATRIX_MULTIPLY
%define MATRIX_MULTIPLY

matrix_multiply:
; void matrix_multiply(double* {rdi}, double* {rsi}, double* {rdx}, uint {rcx}
;	uint {r8}, uint {r9});
; 	Multiplies a {rcx}x{r8} matrix at {rsi} by a {r8}x{r9} matrix at {rdx}
;	and places the result in the {rcx}x{r9} matrix beginning at {rdi}.

	push rdi
	push rsi
	push rdx
	push rcx
	sub rsp,16
	movdqu [rsp],xmm0

	mov r12,r8
	shl r12,3	; {r12} tracks byte-width of matrix 1

	mov r13,r9	
	shl r13,3	; {r13} tracks byte-width of matrix 2
	
.loop_rows:
			; track rows in {rcx}

.loop_cols:
	mov r10,r9	; track columns in {r9}
	pxor xmm0,xmm0	; track running sum in {xmm0}

.internal_loop:
	mov r11,r8	; track internal dot-product in {r11}
	movsd xmm1,

	

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
