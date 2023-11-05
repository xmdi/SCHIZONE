%ifndef LINEAR_LEAST_SQUARES
%define LINEAR_LEAST_SQUARES

%include "lib/math/lin_alg/inverse_2x2.asm"
%include "lib/math/matrix/matrix_multiply.asm"

linear_least_squares:
; void linear_least_squares(double* {rdi}, double* {rsi}, double* {rdx}, 
;	uint rcx);
; Computes the coefficients of the linear least squares approximation relating
; {rcx} independent values starting at address {rsi} with {rcx} dependent
; values starting at address {rdx}.

	push rdi ; [rsp+120]
	push rsi ; [rsp+112]
	push rdx ; [rsp+104]
	push rcx ; [rsp+96]
	sub rsp,96
	movdqu [rsp+0],xmm0
	movdqu [rsp+16],xmm1
	movdqu [rsp+32],xmm2
	movdqu [rsp+48],xmm3
	movdqu [rsp+64],xmm4
	movdqu [rsp+80],xmm5

	; component 1,1 of XTX
	cvtsi2sd xmm0,rcx
	movsd [.XTX+0],xmm0	

	pxor xmm0,xmm0	; component 1,2 and 2,1 of XTX	
	pxor xmm1,xmm1	; component 2,2 of XTX
	pxor xmm2,xmm2	; component 1 of XTY
	pxor xmm3,xmm3	; component 2 of XTY
.loop:
	movsd xmm4,[rsi]
	movsd xmm5,[rdx]
	addsd xmm0,xmm4
	addsd xmm2,xmm5
	mulsd xmm5,xmm4
	mulsd xmm4,xmm4
	addsd xmm1,xmm4
	addsd xmm3,xmm5
	add rsi,8
	add rdx,8
	dec rcx
	jnz .loop

	movsd [.XTX+8],xmm0
	movsd [.XTX+16],xmm0
	movsd [.XTX+24],xmm1
	movsd [.XTY+0],xmm2
	movsd [.XTY+8],xmm3

	mov rdi,.workspace
	mov rsi,.XTX
	call inverse_2x2

	mov rdi,[rsp+120]
	mov rsi,.workspace
	mov rdx,.XTY
	mov rcx,2
	mov r8,1
	mov r9,2
	call matrix_multiply	

	movdqu xmm0,[rsp+0]
	movdqu xmm1,[rsp+16]
	movdqu xmm2,[rsp+32]
	movdqu xmm3,[rsp+48]
	movdqu xmm4,[rsp+64]
	movdqu xmm5,[rsp+80]
	add rsp,96
	pop rcx
	pop rdx
	pop rsi
	pop rdi

	ret

.workspace:
	times 32 db 0

.XTY:
	times 16 db 0

.XTX:
	times 32 db 0

%endif
