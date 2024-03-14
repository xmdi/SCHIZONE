%ifndef TRAPEZOIDAL_METHOD
%define TRAPEZOIDAL_METHOD

trapezoidal_method:
; double {xmm0} trapezoidal_method(void* {rdi}, ulong {rsi}, double {xmm0}, double {xmm1});
; Estimates the definite integral of the function at address {rdi} between {xmm0}<=x<={xmm1} 
; using a trapezoidal method with {rsi} steps. Area returned in {xmm0}.
; Dear user, please don't pass in bogus values for {rsi}, thanks.
; Function of interest should take independent variable and returns dependend variable in {xmm0}.

	push rsi
	sub rsp,64
	movdqu [rsp+0],xmm3
	movdqu [rsp+16],xmm4
	movdqu [rsp+32],xmm5
	movdqu [rsp+48],xmm6

	cvtsi2sd xmm3,rsi
	movsd xmm2,xmm1
	subsd xmm2,xmm0
	divsd xmm2,xmm3
	; step size in {xmm2}

	movsd xmm3,xmm0		; x val track
	pxor xmm4,xmm4		; track sum

	call rdi
	movsd xmm5,xmm0		; LHS in xmm5
	addsd xmm3,xmm2

.loop:
	movsd xmm0,xmm3
	call rdi

	movsd xmm6,xmm0		; RHS in xmm6
	addsd xmm0,xmm5		; LHS+RHS
	mulsd xmm0,[.half]	; (LHS+RHS)/2
	mulsd xmm0,xmm2		; (LHS+RHS)*step/2
	addsd xmm4,xmm0		; add to running sum

	movsd xmm5,xmm6		; LHS <- RHS
	addsd xmm3,xmm2		; increment x val
	dec rsi
	jnz .loop

.ret:
	movsd xmm0,xmm4
	movdqu xmm3,[rsp+0]
	movdqu xmm4,[rsp+16]
	movdqu xmm5,[rsp+32]
	movdqu xmm6,[rsp+48]
	add rsp,64
	pop rsi

	ret		; return

.half:
	dq 0.50
.newline:
	db `\n`
%endif
