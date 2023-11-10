%ifndef QUADRATIC_LEAST_SQUARES
%define QUADRATIC_LEAST_SQUARES

%include "lib/math/lin_alg/inverse_3x3.asm"
%include "lib/math/matrix/matrix_multiply.asm"

quadratic_least_squares:
; void quadratic_least_squares(double* {rdi}, double* {rsi}, double* {rdx}, 
;	uint rcx);
; Computes the coefficients of the quadratic least squares approximation 
; relating {rcx} independent values starting at address {rsi} with {rcx} 
; dependent values starting at address {rdx}.

	push rdi ; [rsp+168]
	push rsi ; [rsp+160]
	push rdx ; [rsp+152]
	push rcx ; [rsp+144]
	sub rsp,144
	movdqu [rsp+0],xmm0
	movdqu [rsp+16],xmm1
	movdqu [rsp+32],xmm2
	movdqu [rsp+48],xmm3
	movdqu [rsp+64],xmm4
	movdqu [rsp+80],xmm5
	movdqu [rsp+96],xmm6
	movdqu [rsp+112],xmm7
	movdqu [rsp+128],xmm8

	; component 1,1 of XTX
	cvtsi2sd xmm0,rcx
	movsd [.XTX+0],xmm0	

	pxor xmm0,xmm0	; component 1,2 and 2,1 of XTX	
	pxor xmm1,xmm1	; component 1,3 and 2,2 and 3,1 of XTX
	pxor xmm2,xmm2	; component 2,3 and 3,2 of XTX
	pxor xmm3,xmm3	; component 3,3 of XTX
	pxor xmm4,xmm4	; component 1 of XTY
	pxor xmm5,xmm5	; component 2 of XTY
	pxor xmm6,xmm6	; component 3 of XTY

.loop:
	movsd xmm7,[rsi]
	movsd xmm8,[rdx]
	addsd xmm0,xmm7
	addsd xmm4,xmm8
	mulsd xmm8,xmm7
	mulsd xmm7,xmm7
	addsd xmm1,xmm7
	addsd xmm5,xmm8
	mulsd xmm7,[rsi]
	mulsd xmm8,[rsi]
	addsd xmm2,xmm7
	addsd xmm6,xmm8
	mulsd xmm7,[rsi]
	addsd xmm3,xmm7
	add rsi,8
	add rdx,8
	dec rcx
	jnz .loop

	movsd [.XTX+8],xmm0
	movsd [.XTX+24],xmm0
	movsd [.XTX+16],xmm1
	movsd [.XTX+32],xmm1
	movsd [.XTX+48],xmm1
	movsd [.XTX+40],xmm2
	movsd [.XTX+56],xmm2
	movsd [.XTX+64],xmm3
	movsd [.XTY+0],xmm4
	movsd [.XTY+8],xmm5
	movsd [.XTY+16],xmm6

	mov rdi,.workspace
	mov rsi,.XTX
	call inverse_3x3

	mov rdi,[rsp+168]
	mov rsi,.workspace
	mov rdx,.XTY
	mov rcx,3
	mov r8,1
	mov r9,3
	call matrix_multiply	

	movdqu xmm0,[rsp+0]
	movdqu xmm1,[rsp+16]
	movdqu xmm2,[rsp+32]
	movdqu xmm3,[rsp+48]
	movdqu xmm4,[rsp+64]
	movdqu xmm5,[rsp+80]
	movdqu xmm6,[rsp+96]
	movdqu xmm7,[rsp+112]
	movdqu xmm8,[rsp+128]
	add rsp,144
	pop rcx
	pop rdx
	pop rsi
	pop rdi

	ret

.workspace:
	times 72 db 0

.XTY:
	times 24 db 0

.XTX:
	times 72 db 0

%endif
