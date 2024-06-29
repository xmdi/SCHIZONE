%ifndef COSINE_BHASKARA
%define COSINE_BHASKARA

; double {xmm0} cosine_bhaskara(double {xmm0});
;	Returns approximation of sine({xmm0}) in {xmm0} using approximation
;	below:
;		cosine(x)~=(pi^2-4x^2)/(pi^2+x^2)

align 64
cosine_bhaskara:

	push rax
	push rbx
	sub rsp,16
	movdqu [rsp+0],xmm1

	xor rax,rax
	xor rbx,rbx	; negate flag

	pslld xmm0,1
	psrld xmm0,1

	movsd xmm1,xmm0
	mulsd xmm1,[.recip_two_pi]
	roundsd xmm1,xmm1,0b11		; truncate xmm8 to integer
	mulsd xmm1,[.two_pi]		; xmm8 is the closest multiple of 2pi
					; of lower absolute value
	subsd xmm0,xmm1			; xmm0 is now within [0,2pi]

	movsd xmm1,[.pi]
	comisd xmm0,xmm1
	jbe .reduced
	movsd xmm1,[.two_pi]
	subsd xmm1,xmm0
	movsd xmm0,xmm1

.reduced:				; xmm0 is now within [0,pi]

	movsd xmm1,[.half_pi]
	comisd xmm0,xmm1
	jbe .reduced2
	movsd xmm1,[.pi]
	subsd xmm1,xmm0
	movsd xmm0,xmm1
	mov rbx,1

.reduced2:				; xmm0 is now within [0,pi/2]

	mulsd xmm0,xmm0
	movsd xmm1,xmm0
	mulsd xmm1,[.four]
	movsd xmm2,[.pi_squared]

	addsd xmm0,xmm2
	subsd xmm2,xmm1

	divsd xmm2,xmm0
	movsd xmm0,xmm2

	test rbx,rbx
	jz .no_neg
	mulsd xmm0,[.neg]

.no_neg:
	
	movdqu xmm1,[rsp+0]
	add rsp,16

	pop rbx
	pop rax

	ret 

align 8

.neg:		; -1
	dq 0xBFF0000000000000

.pi:	; ~3.1
	dq 0x400921FB54442D18

.four:
	dq 0x4010000000000000
	
.half_pi:
	dq 0x3FF921FB54442D18

.pi_squared:
	dq 0x4023bd3cc9be45de

.two_pi:	; ~6.3
	dq 0x401921FB54442D18

.recip_two_pi:	; 1/6.3
	dq 0x3FC45F306DC9C883

%endif

