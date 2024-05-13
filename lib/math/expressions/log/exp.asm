%ifndef EXP
%define EXP

align 16

exp:
; double {xmm0} exp(double {xmm0}, double {xmm1});
;	Computes Taylor Series approximation of e^({xmm0}) to
;	within tolerance {xmm1}, returning in {xmm0}.

	push rdx
	push rcx
	push r8
	sub rsp,112
	movdqu [rsp+0],xmm2
	movdqu [rsp+16],xmm3
	movdqu [rsp+32],xmm4
	movdqu [rsp+48],xmm5
	movdqu [rsp+64],xmm6
	movdqu [rsp+80],xmm7
	movdqu [rsp+96],xmm8

	xor r8,r8	; flag for negative input

	pxor xmm2,xmm2	; {xmm2}=zero for comparison
	comisd xmm0,xmm2
	jae .positive_input
	inc r8	
	pslld xmm0,1
	psrld xmm0,1
.positive_input:
	movsd xmm4,[.one]	
	comisd xmm0,xmm4
	jb .taylor_series_prep

	cvtsd2si rcx,xmm0

.integer_loop:
	mulsd xmm4,[.e]	
	subsd xmm0,[.one]	
	dec rcx
	jnz .integer_loop

.taylor_series_prep:
	movsd xmm2,[.one]	; {xmm2} tracks running sum
	movsd xmm3,xmm0		; {xmm3}=x, multiplier between each term
	movsd xmm5,xmm0		; {xmm5}=x, term numerator
	mov rcx,1		; {rcx} tracks integer denominator, k
	mov rdx,1		; {rdx} tracks denominator factorial

.taylor_series_loop:
	imul rdx,rcx		; compute next factorial term
	cvtsi2sd xmm6,rdx	; convert k! into double in {xmm6}
	movsd xmm7,xmm5		; {xmm7}=x^k
	divsd xmm7,xmm6		; {xmm7}=(x^k)/k!
	movsd xmm8,xmm7
	pslld xmm8,1
	psrld xmm8,1		; {xmm8}=abs((x^k)/k!)
	comisd xmm8,xmm1	; compare current term against tolerance
	jbe .done			; if below, break loop
	addsd xmm2,xmm7			; otherwise, add to running sum
	inc rcx			; increment factorial multiplier
	mulsd xmm5,xmm3		; multiply (x^k)*(x)
	jmp .taylor_series_loop

.done:	
	mulsd xmm2,xmm4	
	cmp r8,1
	jne .leave
; was negative exponent
	movsd xmm0,[.one]
	divsd xmm0,xmm2
	jmp .leave_for_real
.leave:
	movsd xmm0,xmm2
.leave_for_real:	

	movdqu xmm2,[rsp+0]
	movdqu xmm3,[rsp+16]
	movdqu xmm4,[rsp+32]
	movdqu xmm5,[rsp+48]
	movdqu xmm6,[rsp+64]
	movdqu xmm7,[rsp+80]
	movdqu xmm8,[rsp+96]
	add rsp,112
	pop r8
	pop rcx
	pop rdx

	ret

align 8
.one:
	dq 1.0
.e:
	dq 0x4005bf0a8b145769

%endif
