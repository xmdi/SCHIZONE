%ifndef SINE_BHASKARA
%define SINE_BHASKARA

; double {xmm0} sine_bhaskara(double {xmm0});
;	Returns approximation of sine({xmm0}) in {xmm0} using approximation
;	below:
;		sine(x)~=(16x*(pi-x))/(5pi^2-4x*(pi-x))

align 64
sine_bhaskara:

	push rax
	push rbx
	sub rsp,16
	movdqu [rsp+0],xmm1

	xor rax,rax
	xor rbx,rbx	; negate flag

	pxor xmm1,xmm1
	comisd xmm0,xmm1
	jae .no_negate
	pslld xmm0,1
	psrld xmm0,1
	mov rbx,1

.no_negate:

	movsd xmm1,xmm0
	mulsd xmm1,[.recip_two_pi]
	roundsd xmm1,xmm1,0b11		; truncate xmm8 to integer
	mulsd xmm1,[.two_pi]		; xmm8 is the closest multiple of 2pi
					; of lower absolute value
	subsd xmm0,xmm1			; xmm0 is now within [0,2pi]

	movsd xmm1,[.pi]
	comisd xmm0,xmm1
	jbe .reduced
	subsd xmm0,xmm1
	xor rbx,1
.reduced:				; xmm0 is now within [0,pi]


;	sine(x)~=(16x*(pi-x))/(5pi^2-4x*(pi-x))

	movsd xmm1,[.pi]
	subsd xmm1,xmm0
	movsd xmm2,xmm0
	mulsd xmm0,[.sixteen]
	mulsd xmm0,xmm1

	mulsd xmm2,[.four]
	mulsd xmm2,xmm1
	movsd xmm1,[.five_pi_squared]
	subsd xmm1,xmm2

	divsd xmm0,xmm1

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

.sixteen:
	dq 0x4030000000000000
	
.five_pi_squared:
	dq 0x4048AC8BFC2DD756

.two_pi:	; ~6.3
	dq 0x401921FB54442D18

.recip_two_pi:	; 1/6.3
	dq 0x3FC45F306DC9C883

%endif

