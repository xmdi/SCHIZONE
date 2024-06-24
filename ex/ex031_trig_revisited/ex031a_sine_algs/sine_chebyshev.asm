%ifndef SINE_CHEBYSHEV
%define SINE_CHEBYSHEV

; double {xmm0} sine_chebyshev(double {xmm0}, int {rdi});
;	Returns approximation of sine({xmm0}) in {xmm0} using cringe math thing;
;  	thing with number of terms in {rdi}.

align 64
sine_chebyshev:
	
	cmp rdi,0
	jle .error

	push rdi
	push rsi
	push rbx
	sub rsp,96
	movdqu [rsp+0],xmm1
	movdqu [rsp+16],xmm2
	movdqu [rsp+32],xmm3
	movdqu [rsp+48],xmm4
	movdqu [rsp+64],xmm5
	movdqu [rsp+80],xmm6

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

	movsd xmm2,[.half_pi]
	comisd xmm0,xmm2
	jbe .reduced2
	subsd xmm0,xmm1
	mulsd xmm0,[.neg]
	
.reduced2:				; xmm0 is now within [0,pi/2]

	movsd xmm1,xmm0 		; t for T(t) in {xmm1}
	mulsd xmm1,xmm1
	mulsd xmm1,[.conversion]
	addsd xmm1,[.neg]

	movsd xmm2,[.one] 		; T(n-1)
	movsd xmm3,xmm1 		; T(n)
					; T(n+1) = 2x*T(n)-T(n-1)
	cmp rdi,1
	je .single_term
	cmp rdi,2
	je .two_terms

	movsd xmm5,xmm2
	movsd xmm6,xmm3
	mulsd xmm5,[.cheby_coefficients]
	mulsd xmm6,[.cheby_coefficients+8]
	addsd xmm5,xmm6
	movsd xmm4,xmm5
	
	mov rsi,.cheby_coefficients+16
	sub rdi,2

.loop:	
	
	; compute next T(t)
	movsd xmm5,xmm3
	mulsd xmm5,xmm1
	mulsd xmm5,[.two]
	subsd xmm5,xmm2

	; shift T(t)s down
	movsd xmm2,xmm3
	movsd xmm3,xmm5

	; current term contribution to running sum
	movsd xmm6,[rsi]

	mulsd xmm6,xmm3
	addsd xmm4,xmm6

	; next term
	add rsi,8
	dec rdi
	jnz .loop

.ret:

	mulsd xmm0,xmm4

	; TODO SIGN THING
	test rbx,rbx
	jz .no_neg
	mulsd xmm0,[.neg]

.no_neg:

	movdqu xmm1,[rsp+0]
	movdqu xmm2,[rsp+16]
	movdqu xmm3,[rsp+32]
	movdqu xmm4,[rsp+48]
	movdqu xmm5,[rsp+64]
	movdqu xmm6,[rsp+80]
	add rsp,96
	pop rbx
	pop rsi
	pop rdi

.error:
	ret 

.single_term:

	movsd xmm4,[.cheby_coefficients]
	jmp .ret

.two_terms:

	mulsd xmm2,[.cheby_coefficients]
	mulsd xmm3,[.cheby_coefficients+8]
	addsd xmm2,xmm3
	movsd xmm4,xmm2
	jmp .ret

align 8

.test:
	dq 0.25

.conversion: ; 8/pi^2
	dq 0x3fe9f02f6222c720

.one:		; +1
	dq 0x3FF0000000000000

.two:		; +2
	dq 0x4000000000000000

.neg:		; -1
	dq 0xBFF0000000000000

.half_pi:
	dq 0x3FF921FB54442D18

.pi:	; ~3.1
	dq 0x400921FB54442D18

.two_pi:	; ~6.3
	dq 0x401921FB54442D18

.recip_two_pi:	; 1/6.3
	dq 0x3FC45F306DC9C883

.cheby_coefficients:
	dq 0x3fea00094652cdda
	dq 0xbfc73ec5ae4c1553
	dq 0x3f77c6adc7f47c78
	dq 0xbf16cb67b38bec9b
	dq 0x3ea94ffd7fbaa2d6
	dq 0xbe3253c2391c9f0c
	dq 0x3db2ab906c56b957
	dq 0xbd2c3722fbb436b3
	dq 0x3ca07195ba656098
	dq 0xbc0e76fd08acd8d8
	dq 0x3b76f7a088b7acc0
	dq 0xbadcbb7f6b1d0b7f
	dq 0x3a3e4dbd7f04bb99
	dq 0xb99b4f60eb2bd21e
	dq 0x38f546117af26189
	dq 0xb84cf46268b07c8d
	dq 0x37a2d0f601a9d980

%endif
