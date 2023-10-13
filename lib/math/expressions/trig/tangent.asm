%ifndef TANGENT
%define TANGENT

tangent:
; double {xmm0} tangent(double {xmm0}, double {xmm1});
; Computes partial fraction expansion of tangent({xmm0})
; until the added term is less than the tolerance in {xmm1}
; (not real tolerance FYI). Return value in {xmm0}.

	push rcx
	sub rsp,96
	movdqu [rsp+0],xmm1
	movdqu [rsp+16],xmm2
	movdqu [rsp+32],xmm3
	movdqu [rsp+48],xmm4
	movdqu [rsp+64],xmm5
	movdqu [rsp+80],xmm6

	; adjust input xmm0 to within range -pi/2 to +pi/2

	comisd xmm0,[.pi]
	jae .big_shift
	comisd xmm0,[.neg_pi]
	jbe .big_shift
	jmp .check_upper_bound

.big_shift:
	movsd xmm2,xmm0		; xmm2=x
	mulsd xmm2,[.inv_pi]	; xmm2=x/pi
	roundsd xmm2,xmm2,0b11	; truncate xmm2 to integer
	mulsd xmm2,[.pi]	; xmm2 is the closest multiple of pi
				; of lower absolute value
	subsd xmm0,xmm2		; xmm0 is now within +/-pi

.check_upper_bound:
	comisd xmm0,[.half_pi]		; if x<=pi/2
	jbe .check_lower_bound		; we gucci
	subsd xmm0,[.pi]		; otherwise subtract pi
	jmp .get_ready
.check_lower_bound:
	comisd xmm0,[.neg_half_pi]	; if x>=-pi/2
	jae .get_ready			; we still gucci
	addsd xmm0,[.pi]		; otherwise add pi

.get_ready:

	mulsd xmm0,[.inv_pi]
	movsd xmm2,xmm0
	addsd xmm2,xmm2	; {xmm2} = 2x
	movsd xmm3,xmm0
	mulsd xmm3,xmm3	; {xmm3} = x^2
	xor rcx,rcx

	mulsd xmm1,[.pi]
	divsd xmm1,xmm2	; {xmm1} = tolerance scaled

	pslld xmm1,1	; abs(tolerance)
	psrld xmm1,1

	pxor xmm0,xmm0

.loop:
	cvtsi2sd xmm4,rcx
	addsd xmm4,[.half]
	mulsd xmm4,xmm4
	subsd xmm4,xmm3

	movsd xmm5,[.one]
	divsd xmm5,xmm4

	movsd xmm6,xmm5
	addsd xmm0,xmm5
	inc rcx	

	pslld xmm6,1
	psrld xmm6,1
	comisd xmm6,xmm1	; compare current term against tolerance
	ja .loop		; if we are below tolerance, exit loop

	mulsd xmm0,xmm2
	mulsd xmm0,[.inv_pi]
	
	movdqu xmm1,[rsp+0]
	movdqu xmm2,[rsp+16]
	movdqu xmm3,[rsp+32]
	movdqu xmm4,[rsp+48]
	movdqu xmm5,[rsp+64]
	movdqu xmm6,[rsp+80]
	add rsp,96
	pop rcx

	ret						; return


align 8	; need to align to use items below

.one:	; ~1
	dq 1.0

.half:	; ~.5
	dq 0.5

.pi:	; ~3.1
	dq 0x400921FB54442D18

.neg_pi:; ~-3.1
	dq 0xC00921FB54442D18

.inv_pi: ; ~.3
	dq 0x3FD45F306DC9C883

.half_pi:	; ~1.7
	dq 0x3FF921FB54442D18

.neg_half_pi:	; ~-1.7
	dq 0xBFF921FB54442D18

%endif	
