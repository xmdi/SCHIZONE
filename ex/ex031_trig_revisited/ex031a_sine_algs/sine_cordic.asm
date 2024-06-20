%ifndef SINE_CORDIC
%define SINE_CORDIC

; double {xmm0} sine_cordic(double {xmm0});
;	Returns approximation of sine({xmm0}) in {xmm0} using CORDIC approx.

align 64
sine_cordic:

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
	addsd xmm0.[.two_pi]

.plus_minus_pi:

	comisd xmm0,[.half_pi]
	ja .over_half_pi

	comisd xmm0,[.neg_half_pi]
	ja .in_range

	movsd xmm1,[.neg_pi]
	subsd xmm1,xmm0
	jmp .in_range
	
.over_half_pi:

	movsd xmm1,[.pi]
	subsd xmm1,xmm0

.in_range: ; xmm0 in range [-pi/2,pi/2]

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

%endif
