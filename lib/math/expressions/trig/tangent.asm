%ifndef TANGENT
%define TANGENT

tangent:
; double {xmm0} tangent(double {xmm0}, double {xmm1});
; computes partial fraction expansion of tangent({xmm0})
; to within tolerance {xmm1}, return value in {xmm0}

	push rcx
	push rdx
	sub rsp,64
	movdqu [rsp+0],xmm8
	movdqu [rsp+16],xmm9
	movdqu [rsp+32],xmm10
	movdqu [rsp+48],xmm11

; adjust input xmm0 to within range -pi to +pi

	comisd xmm0,[.2pi]
	jae .big_shift
	comisd xmm0,[.neg_2pi]
	jbe .big_shift
	jmp .check_upper_bound

.big_shift:
	movsd xmm8,xmm0			; xmm8=x
	mulsd xmm8,[.recip_2pi]	; xmm8=x/2pi
	roundsd xmm8,xmm8,0b11	; truncate xmm8 to integer
	mulsd xmm8,[.2pi]		; xmm8 is the closest multiple of 2pi
							; of lower absolute value
	subsd xmm0,xmm8			; xmm0 is now within +/-2pi

.check_upper_bound:
	comisd xmm0,[.pi]			; if x<=pi
	jbe .check_lower_bound		; we gucci
	subsd xmm0,[.2pi]			; otherwise subtract 2pi
	jmp .get_ready
.check_lower_bound:
	comisd xmm0,[.neg_pi]		; if x>=-pi
	jae .get_ready				; we still gucci
	addsd xmm0,[.2pi]			; otherwise add 2pi

.get_ready:
	mulsd xmm0,[.inv_pi]
	movsd xmm2,xmm0
	addsd xmm2,xmm2	; {xmm2} = 2x
	movsd xmm3,xmm0
	mulsd xmm3,xmm3	; {xmm3} = x^2
	xor rcx,rcx

	mulsd xmm1,[.pi]
	divsd xmm1,xmm2	; {xmm1} = tolerance scaled

	pxor xmm0,xmm0

.loop:
	cvtsi2sd xmm4,rcx
	addsd xmm4,[.half]
	mulsd xmm4,xmm4
	subsd xmm4,xmm3

	movsd xmm5,[.one]
	divsd xmm5,xmm4

	movsd xmm6,xmm5
	
	pslld xmm6,1
	psrld xmm6,1
	comisd xmm6,xmm1	; compare current term against tolerance
	jbe .done		; if we are below tolerance, exit loop
	
	addsd xmm0,xmm5		; add to running count
	inc rcx
	jmp .loop

.done:
	mulsd xmm0,xmm2
	mulsd xmm0,[.inv_pi]

	ret

	movdqu xmm8,[rsp+0]
	movdqu xmm9,[rsp+16]
	movdqu xmm10,[rsp+32]
	movdqu xmm11,[rsp+48]
	add rsp,64
	pop rdx
	pop rcx

	ret						; return


align 8	; need to align to use items below

.neg:	; to negate 64-bit float
	dq 0x8000000000000000

.pi:	; ~3.1
	dq 0x400921FB54442D18

.neg_pi:	; ~-3.1
	dq 0xC00921FB54442D18

.2pi:	; ~6.3
	dq 0x401921FB54442D18

.neg_2pi:	; ~-6.3
	dq 0xC01921FB54442D18

.recip_2pi:	; 1/6.3
	dq 0x3FC45F306DC9C883

%endif	
