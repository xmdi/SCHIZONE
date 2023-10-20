%ifndef NEWTONS_METHOD
%define NEWTONS_METHOD

newtons_method:
; ulong {rax}, double {xmm0} newtons_method(void* {rdi}, void* {rsi},
;		double {xmm0}, double {xmm1});
;	Uses Newton's method to find a root for the single-variable 
;	function at address {rdi}, with slope function at address {rsi}
;	with initial guess {xmm0} to within tolerance {xmm1}. 
;	On fail, {rax}=0. On success, the root is returned 
;	in {xmm0}, and {rax} contains the number of iterations.
;
;	The functions of interest at {rdi} and {rsi} should be of the form:
;		double {xmm0} func(double {xmm0});
;	and should not affect any registers besides {xmm0}.

	sub rsp,48
	movdqu [rsp+0],xmm2
	movdqu [rsp+16],xmm3
	movdqu [rsp+32],xmm4

	xor rax,rax		; count number of iterations in {rax}

	; new x in {xmm3}
	; old x in {xmm4} (used for tolerance)
	; current f(x) in {xmm2}
	; current f'(x) in {xmm0}
	
	movsd xmm3,xmm0
	jmp .start
	
.loop:

	subsd xmm4,xmm3

	pslld xmm4,1
	psrld xmm4,1
	comisd xmm4,xmm1
	jbe .ret	

.start:

	movsd xmm0,xmm3
	call rdi	
	movsd xmm2,xmm0		; {xmm2} = f(x);

	movsd xmm0,xmm3
	call rsi
	
	divsd xmm2,xmm0		; f(x)/f'(x)
	movsd xmm4,xmm3		; old x
	subsd xmm3,xmm2		; new x

	inc rax

	jmp .loop

.ret:
	movsd xmm0,xmm3
	movdqu xmm2,[rsp+0]
	movdqu xmm3,[rsp+16]
	movdqu xmm4,[rsp+32]
	add rsp,48

	ret			; return

%endif
