%ifndef MATRIX_SET_IDENTITY
%define MATRIX_SET_IDENTITY

matrix_set_identity:
; void matrix_set_identity(double* {rdi}, uint {rsi}, uint {rdx});
; 	Sets {rsi}x{rdx} double-precision floating point matrix beginning 
;	at {rdi} to an identity matrix.

	push rdi
	push rsi
	push rcx
	sub rsp,32
	movdqu [rsp+16],xmm1
	movdqu [rsp],xmm0

	pxor xmm0,xmm0		; {xmm0}=0
	movsd xmm1,[.one]	; {xmm1}=1

	mov rcx,rdx		; {rcx}=number of columns
	movsd [rdi],xmm1	; set first diagonal
	add rdi,8

.next_diagonal:
	movsd [rdi],xmm0	; place off-diagonal element
	add rdi,8
	dec rcx
	jnz .next_diagonal	; loop for {rcx}+1 elements
	
	mov rcx,rdx
	movsd [rdi],xmm1	; place diagonal element
	add rdi,8
	dec rsi			; loop for {rsi} rows
	jnz .next_diagonal
	
	movdqu xmm1,[rsp+16]
	movdqu xmm0,[rsp]
	add rsp,32
	pop rcx
	pop rsi
	pop rdi

	ret			; return

.one:
	dq 1.0

%endif
