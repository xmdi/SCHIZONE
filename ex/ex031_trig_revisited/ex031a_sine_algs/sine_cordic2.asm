%ifndef SINE_CORDIC2
%define SINE_CORDIC2

; double {xmm0}, double {xmm1} sine_cordic2(double {xmm0});
;	Returns approximation of sine({xmm0}) and cosine({xmm1}) in {xmm0} and 
;	{xmm1} respectively using CORDIC approx.

align 64
sine_cordic2:

	push rdi
	push rsi
	push rcx
	sub rsp,80
	movdqu [rsp+0],xmm2
	movdqu [rsp+16],xmm3
	movdqu [rsp+32],xmm4
	movdqu [rsp+48],xmm5
	movdqu [rsp+64],xmm6

	movsd xmm1,xmm0
	pslld xmm1,1
	psrld xmm1,1
	comisd xmm1,[.pi]
	jbe .plus_minus_pi

	movsd xmm1,xmm0
	mulsd xmm1,[.recip_two_pi]
	roundsd xmm1,xmm1,0b11		; truncate xmm8 to integer
	mulsd xmm1,[.two_pi]		; xmm8 is the closest multiple of 2pi
					; of lower absolute value
	subsd xmm0,xmm1			; xmm0 is now within [-2pi,2pi]
	
	movsd xmm1,xmm0
	pslld xmm1,1
	psrld xmm1,1
	comisd xmm1,[.pi]
	jbe .plus_minus_pi
	pxor xmm1,xmm1
	comisd xmm0,xmm1
	jb .less_than_neg_pi
.greater_than_pi:
	subsd xmm0,[.two_pi]
	jmp .plus_minus_pi
.less_than_neg_pi:	
	addsd xmm0,[.two_pi]

.plus_minus_pi:

	comisd xmm0,[.half_pi]
	ja .over_half_pi

	comisd xmm0,[.neg_half_pi]
	ja .in_range

	movsd xmm1,[.neg_pi]
	subsd xmm1,xmm0
	movsd xmm0,xmm1
	jmp .in_range
	
.over_half_pi:

	movsd xmm1,[.pi]
	subsd xmm1,xmm0
	movsd xmm0,xmm1

.in_range: ; xmm0 in range [-pi/2,pi/2]

	pxor xmm1,xmm1			; theta
	movsd xmm2,[.P_table+0]		; x
	pxor xmm3,xmm3			; y
	; xmm5 temp for x
	; xmm6 temp

	mov rdi,.atan_table
	mov rsi,.P_table

	mov rcx,16
.loop:

	comisd xmm1,xmm0
	jb .pos_sigma
.neg_sigma:
	subsd xmm1,[rdi]
	
	movsd xmm5,xmm2
	movsd xmm6,xmm3
	mulsd xmm6,[rsi]
	addsd xmm2,xmm6

	mulsd xmm5,[rsi]
	subsd xmm3,xmm5

	jmp .skip
.pos_sigma:
	addsd xmm1,[rdi]

	movsd xmm5,xmm2
	movsd xmm6,xmm3
	mulsd xmm6,[rsi]
	subsd xmm2,xmm6

	mulsd xmm5,[rsi]
	addsd xmm3,xmm5

.skip:

	add rdi,8
	add rsi,8

	dec rcx	
	jnz .loop

	mulsd xmm2,[.k_factor]
	mulsd xmm3,[.k_factor]

	movsd xmm0,xmm2
	movsd xmm1,xmm3

.ret:

	movdqu xmm2,[rsp+0]
	movdqu xmm3,[rsp+16]
	movdqu xmm4,[rsp+32]
	movdqu xmm5,[rsp+48]
	movdqu xmm6,[rsp+64]
	add rsp,80

	pop rcx
	pop rsi
	pop rdi

	ret 

align 8

.k_factor:
	dq 0x3FE36E9DB5156034

.half_pi:	; ~3.1/2
	dq 0x3FF921FB54442D18

.neg_half_pi:	; ~-3.1/2
	dq 0xBFF921FB54442D18

.pi:	; ~3.1
	dq 0x400921FB54442D18

.neg_pi:	; -~3.1
	dq 0xC00921FB54442D18

.two_pi:	; ~6.3
	dq 0x401921FB54442D18

.recip_two_pi:	; 1/6.3
	dq 0x3FC45F306DC9C883

.atan_table:
	dq 0x3fe921fb54442d18
	dq 0x3fddac670561bb4f
	dq 0x3fcf5b75f92c80dd
	dq 0x3fbfd5ba9aac2f6e
	dq 0x3faff55bb72cfdea
	dq 0x3f9ffd55bba97625
	dq 0x3f8fff555bbb729b
	dq 0x3f7fffd555bbba97
	dq 0x3f6ffff5555bbbb7
	dq 0x3f5ffffd5555bbbc
	dq 0x3f4fffff55555bbc
	dq 0x3f3fffffd55555bc
	dq 0x3f2ffffff555555c
	dq 0x3f1ffffffd555556
	dq 0x3f0fffffff555555
	dq 0x3effffffffd55555

.P_table:
	dq 0x3ff0000000000000
	dq 0x3fe0000000000000
	dq 0x3fd0000000000000
	dq 0x3fc0000000000000
	dq 0x3fb0000000000000
	dq 0x3fa0000000000000
	dq 0x3f90000000000000
	dq 0x3f80000000000000
	dq 0x3f70000000000000
	dq 0x3f60000000000000
	dq 0x3f50000000000000
	dq 0x3f40000000000000
	dq 0x3f30000000000000
	dq 0x3f20000000000000
	dq 0x3f10000000000000
	dq 0x3f00000000000000

%endif
