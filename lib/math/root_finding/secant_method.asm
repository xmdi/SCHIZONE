%ifndef SECANT_METHOD
%define SECANT_METHOD

secant_method:
; ulong {rax}, double {xmm0} secant_method(void* {rdi}, double {xmm0}, 
;					double {xmm1}, double {xmm2});
;	Uses the secant method to find a root for the single-variable 
;	function at address {rdi} with initial guesses {xmm0} and {xmm1}
;	to within tolerance {xmm2}. On fail, {rax}=0. On success, the 
;	root is returned in {xmm0}, and {rax} contains the number of 
;	iterations.
;
;	The function of interest at address {rdi} should be of the form:
;		double {xmm0} func(double {xmm0});
;	and should not affect any registers besides {xmm0}.

	sub rsp,80
	movdqu [rsp+0],xmm1
	movdqu [rsp+16],xmm3
	movdqu [rsp+32],xmm4
	movdqu [rsp+48],xmm5
	movdqu [rsp+64],xmm6

	xor rax,rax		; count number of iterations in {rax}

.loop:
	movsd xmm3,xmm1		; (x2-x1) in {xmm3}
	subsd xmm3,xmm0

	movsd xmm6,xmm3
	pslld xmm6,1
	psrld xmm6,1
	comisd xmm6,xmm2
	jbe .ret	

	call rdi	
	movsd xmm4,xmm0		; {xmm4} = f(x1);

	movsd xmm0,xmm1
	call rdi

	movsd xmm5,xmm0		; {xmm5} = f(x2);

	mulsd xmm3,xmm5		; f(x2)*(x2-x1)
	subsd xmm5,xmm4		; f(x2)-f(x1)
	divsd xmm3,xmm5		; f(x2)*(x2-x1)*(f(x2)-f(x1))

	movsd xmm0,xmm1		; new x1
	subsd xmm1,xmm3		; new x2

	inc rax

	jmp .loop

.ret:
	movdqu xmm1,[rsp+0]
	movdqu xmm3,[rsp+16]
	movdqu xmm4,[rsp+32]
	movdqu xmm5,[rsp+48]
	movdqu xmm6,[rsp+64]
	add rsp,80

	ret			; return

.zero:
	dq 0.0
.half:
	dq 0.5

%endif
