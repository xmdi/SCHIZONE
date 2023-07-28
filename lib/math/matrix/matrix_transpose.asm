%ifndef MATRIX_TRANSPOSE
%define MATRIX_TRANSPOSE

matrix_transpose:
; void matrix_transpose(double* {rdi}, double* {rsi}, uint {rdx}, uint {rcx});
; 	Transposes {rdx}x{rcx} double-precision floating point matrix beginning 
;	at {rsi} into the {rcx}x{rdx} matrix starting at address {rdi}.

;	NOTE: should work on matrices of any 8-byte datatype.

	push rdi
	push rsi
	push rax
	push rbx
	push rcx
	push r8
	push r9
	push r10

	mov r9,rcx
	imul r9,rdx
	shl r9,3	; {r9} points past the last element of
	add r9,rsi	; the source matrix

	mov r8,rcx	; set row counter in {r8}
	mov r10,rdx
	shl r10,3	; convert {r10} into byte-width
	mov rbx,rdi	; set {rbx} to start of destination matrix

.loop:
	mov rax,[rsi]	; grab element from source matrix
	mov [rbx],rax	; drop element into destination matrix
	add rsi,8	; increment element in source matrix
	add rbx,r10	; move to next row in destination matrix

	dec r8		; loop until out of rows
	jnz .loop

	cmp rsi,r9	; quit when out of elements
	jge .done

	mov r8,rcx	; reset row counter
	add rdi,8	; move to next column of destination matrix	
	mov rbx,rdi	; set {rsi} to next column of destination matrix
		
	jmp .loop

.done:
	pop r10
	pop r9
	pop r8
	pop rcx
	pop rbx
	pop rax	
	pop rsi
	pop rdi

	ret			; return

%endif
