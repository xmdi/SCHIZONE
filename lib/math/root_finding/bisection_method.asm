%ifndef BISECTION_METHOD
%define BISECTION_METHOD

bisection_method:
; ulong {rax}, double {xmm0} bisection_method(void* {rdi}, double {xmm0}, 
;					double {xmm1}, double {xmm2});
;	Uses a bisection method to find a root for the single-variable 
;	function at address {rdi} between lower bound {xmm0} and upper bound 
;	{xmm1} to within tolerance {xmm2}. On fail, {rax}=0. On success, the root 
;	is returned in {xmm0}, and {rax} contains the number of bisection 
;	iterations.
;
;	The function of interest at address {rdi} should be of the form:
;		double {xmm0} func(double {xmm0});
;	and should not affect any registers besides {xmm0}.

	push rdx
	sub rsp,80
	movdqu [rsp+0],xmm1
	movdqu [rsp+16],xmm3
	movdqu [rsp+32],xmm4
	movdqu [rsp+48],xmm5
	movdqu [rsp+64],xmm6

	xor rax,rax		; count number of iterations in {rax}
	movsd xmm3,xmm0		; lower bound in {xmm3}
				; upper bound in {xmm1}
	
	call rdi	
	movsd xmm4,xmm0		; {xmm4} = func(lower_bound);

	movsd xmm0,xmm1
	call rdi
	movsd xmm5,xmm0		; {xmm5} = func(upper_bound);

	mulsd xmm0,xmm4		; {xmm0} = func(u)*func(l)	
	
	comisd xmm0,[.zero]
	jae .ret		; if negative, bounds are valid
				; if positive, bounds are invalid

.valid_bounds:
	mov rdx,0		; orientation flag 
				; (zero means lower bound negative)
				; (nonzero means upper bound negative)
	comisd xmm4,[.zero]
	jb .loop		; set orientation flag
	inc rdx
.loop:

	inc rax
	; check tolerance
	movsd xmm0,xmm1
	subsd xmm0,xmm3
	pslld xmm0,1
	psrld xmm0,1
	comisd xmm0,xmm2
	jbe .converged

	movsd xmm0,xmm3
	addsd xmm0,xmm1
	mulsd xmm0,[.half]	; {xmm0} = midpoint of the upper and lower bound
	movsd xmm6,xmm0		; save midpoint in {xmm6}sdd
	call rdi		; call function to evaluate {xmm0}=func({xmm0});

	comisd xmm0,[.zero]	; based on error...
	jb .value_negative
.value_positive:		; ...adjust the bounds accordingly
	test rdx,1
	jz .replace_upper_bound
	jmp .replace_lower_bound
.value_negative:		; ...adjust the bounds accordingly
	test rdx,1
	jz .replace_lower_bound
.replace_upper_bound:
	movsd xmm1,xmm6
	movsd xmm5,xmm0
	jmp .loop
.replace_lower_bound:
	movsd xmm3,xmm6
	movsd xmm4,xmm0
	jmp .loop

.converged:			; when converged
	movsd xmm0,xmm6		; set return value

.ret:
	movdqu xmm1,[rsp+0]
	movdqu xmm3,[rsp+16]
	movdqu xmm4,[rsp+32]
	movdqu xmm5,[rsp+48]
	movdqu xmm6,[rsp+64]
	add rsp,80
	pop rdx

	ret			; return

.zero:
	dq 0.0
.half:
	dq 0.5

%endif
