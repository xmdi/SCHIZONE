%ifndef SINE_CORDIC
%define SINE_CORDIC

; double {xmm0} sine_cordic(double {xmm0}, uint {rdi});
;	Returns approximation of sine({xmm0}) in {xmm0} using CORDIC approx with 
;	{rdi} iterations.

align 64
sine_cordic:

	push rdi
	push rsi
	push rcx

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

	mov rcx,rdi

	mov rdi,.atan_table
	mov rsi,.P_table

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

	mov rdi,[rsp+16]
	dec rdi
	shl rdi,3
	add rdi,.k_factors
	mulsd xmm3,[rdi]

	movsd xmm0,xmm3

.ret:
	pop rcx
	pop rsi
	pop rdi

	ret 

align 8

.k_factors:
        dq 0x3fe6a09e667f3bcc ; n=1
        dq 0x3fe43d136248490e ; n=2
        dq 0x3fe3a261ba6d7a36 ; n=3
        dq 0x3fe37b9141deb3fe ; n=4
        dq 0x3fe371dac182eef5 ; n=5
        dq 0x3fe36f6cfabd961f ; n=6
        dq 0x3fe36ed1869f27e9 ; n=7
        dq 0x3fe36eaaa970b20f ; n=8
        dq 0x3fe36ea0f222a6d1 ; n=9
        dq 0x3fe36e9e844efd24 ; n=10
        dq 0x3fe36e9de8da104b ; n=11
        dq 0x3fe36e9dc1fcd4ee ; n=12
        dq 0x3fe36e9db8458614 ; n=13
        dq 0x3fe36e9db5d7b25d ; n=14
        dq 0x3fe36e9db53c3d6f ; n=15
        dq 0x3fe36e9db5156034 ; n=16
        dq 0x3fe36e9db50ba8e5 ; n=17
        dq 0x3fe36e9db5093b11 ; n=18
        dq 0x3fe36e9db5089f9c ; n=19
        dq 0x3fe36e9db50878bf ; n=20
        dq 0x3fe36e9db5086f08 ; n=21
        dq 0x3fe36e9db5086c9a ; n=22
        dq 0x3fe36e9db5086bff ; n=23
        dq 0x3fe36e9db5086bd8 ; n=24
        dq 0x3fe36e9db5086bce ; n=25
        dq 0x3fe36e9db5086bcc ; n=26
        dq 0x3fe36e9db5086bcc ; n=27
        dq 0x3fe36e9db5086bcc ; n=28
        dq 0x3fe36e9db5086bcc ; n=29
        dq 0x3fe36e9db5086bcc ; n=30
        dq 0x3fe36e9db5086bcc ; n=31
        dq 0x3fe36e9db5086bcc ; n=32

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
        dq 0x3fe921fb54442d18 ; n=1
        dq 0x3fddac670561bb4f ; n=2
        dq 0x3fcf5b75f92c80dd ; n=3
        dq 0x3fbfd5ba9aac2f6e ; n=4
        dq 0x3faff55bb72cfdea ; n=5
        dq 0x3f9ffd55bba97625 ; n=6
        dq 0x3f8fff555bbb729b ; n=7
        dq 0x3f7fffd555bbba97 ; n=8
        dq 0x3f6ffff5555bbbb7 ; n=9
        dq 0x3f5ffffd5555bbbc ; n=10
        dq 0x3f4fffff55555bbc ; n=11
        dq 0x3f3fffffd55555bc ; n=12
        dq 0x3f2ffffff555555c ; n=13
        dq 0x3f1ffffffd555556 ; n=14
        dq 0x3f0fffffff555555 ; n=15
        dq 0x3effffffffd55555 ; n=16
        dq 0x3eeffffffff55555 ; n=17
        dq 0x3edffffffffd5555 ; n=18
        dq 0x3ecfffffffff5555 ; n=19
        dq 0x3ebfffffffffd555 ; n=20
        dq 0x3eaffffffffff555 ; n=21
        dq 0x3e9ffffffffffd55 ; n=22
        dq 0x3e8fffffffffff55 ; n=23
        dq 0x3e7fffffffffffd5 ; n=24
        dq 0x3e6ffffffffffff5 ; n=25
        dq 0x3e5ffffffffffffd ; n=26
        dq 0x3e4fffffffffffff ; n=27
        dq 0x3e40000000000000 ; n=28
        dq 0x3e30000000000000 ; n=29
        dq 0x3e20000000000000 ; n=30
        dq 0x3e10000000000000 ; n=31
        dq 0x3e00000000000000 ; n=32

.P_table:
        dq 0x3ff0000000000000 ; n=1
        dq 0x3fe0000000000000 ; n=2
        dq 0x3fd0000000000000 ; n=3
        dq 0x3fc0000000000000 ; n=4
        dq 0x3fb0000000000000 ; n=5
        dq 0x3fa0000000000000 ; n=6
        dq 0x3f90000000000000 ; n=7
        dq 0x3f80000000000000 ; n=8
        dq 0x3f70000000000000 ; n=9
        dq 0x3f60000000000000 ; n=10
        dq 0x3f50000000000000 ; n=11
        dq 0x3f40000000000000 ; n=12
        dq 0x3f30000000000000 ; n=13
        dq 0x3f20000000000000 ; n=14
        dq 0x3f10000000000000 ; n=15
        dq 0x3f00000000000000 ; n=16
        dq 0x3ef0000000000000 ; n=17
        dq 0x3ee0000000000000 ; n=18
        dq 0x3ed0000000000000 ; n=19
        dq 0x3ec0000000000000 ; n=20
        dq 0x3eb0000000000000 ; n=21
        dq 0x3ea0000000000000 ; n=22
        dq 0x3e90000000000000 ; n=23
        dq 0x3e80000000000000 ; n=24
        dq 0x3e70000000000000 ; n=25
        dq 0x3e60000000000000 ; n=26
        dq 0x3e50000000000000 ; n=27
        dq 0x3e40000000000000 ; n=28
        dq 0x3e30000000000000 ; n=29
        dq 0x3e20000000000000 ; n=30
        dq 0x3e10000000000000 ; n=31
        dq 0x3e00000000000000 ; n=32

%endif
