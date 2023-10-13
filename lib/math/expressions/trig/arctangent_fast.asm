%ifndef ARCTANGENT_FAST
%define ARCTANGENT_FAST

arctangent_fast:
; double {xmm0} arctangent_fast(double {xmm0}, double {xmm1});
; computes a low order approximation of atan({xmm0}/{xmm1})
; (Note the order!, y/x, first input over second input!)
; return value in {xmm0}

; this routine might be referred to as "atan2_fast" if I was a boomer

; the approximation is pi/4*z - z(abs(z)-1) * (.2447+.0663*abs(z))
; where z=y/x

	push rcx
	sub rsp,48
	movdqu [rsp+0],xmm1
	movdqu [rsp+16],xmm2
	movdqu [rsp+32],xmm3

; check special cases
	pxor xmm3,xmm3
	comisd xmm1,xmm3
	jne .not_special_case
	comisd xmm0,xmm3
	ja .ret_half_pi
	jb .ret_neg_half_pi
.ret_NaN:
	movsd xmm0,[.NaN]
	jmp .ret
.ret_half_pi:
	movsd xmm0,[.half_pi]
	jmp .ret
.ret_neg_half_pi:
	movsd xmm0,[.neg_half_pi]
	jmp .ret

; not a special case
.not_special_case:
	; put the atan2 correction value into {xmm3} for later (to get from left 2 quadrants to right 2 quadrants)
		;+0.0 for x>0
		;+pi for x<0, y>=0
		;-pi for x<0, y<0
	comisd xmm1,xmm3
	ja .start_estimate ; if x>0, {xmm3}=0.0, then start
	comisd xmm0,xmm3
	jb .neg_y
.pos_y:	; if x<0 & y>=0, {xmm3}=+pi, then start
	movsd xmm3,[.pi]
	jmp .start_estimate
.neg_y:	; if x<0 & y<0, {xmm3}=-pi, then start
	movsd xmm3,[.neg_pi]

.start_estimate:
					; we will apply atan(z)=pi/4-atan(1/z) to reduce the range
	xor rcx,rcx		; {rcx} flag tracks if we were originally out of range of (-1,1) on z
	movsd xmm2,xmm0
	divsd xmm0,xmm1		; start by assigning z=y/x
	comisd xmm0,[.one]
	ja .invert_down
	comisd xmm0,[.neg_one]
	ja .go
.invert_up:
	inc rcx
	movsd xmm0,xmm2
	divsd xmm1,xmm0
	movsd xmm0,xmm1
	addsd xmm3,[.neg_half_pi]
	jmp .go
.invert_down:
	inc rcx
	movsd xmm0,xmm2
	divsd xmm1,xmm0
	movsd xmm0,xmm1
	addsd xmm3,[.half_pi]

.go:
					; {xmm0} contains z
	movsd xmm1,xmm0
	pslld xmm1,1
	psrld xmm1,1	; {xmm1} contains abs(z)
	movsd xmm2,xmm1	; {xmm2} contains abs(z) too	
	mulsd xmm2,[.coeff2]
	addsd xmm2,[.coeff1]	; {xmm2} contains (.2447+.0663*abs(z))
	subsd xmm1,[.one]		; {xmm1} contains (abs(z)-1)
	mulsd xmm1,xmm2			; {xmm1} contains (abs(z)-1)(.2447+.0663*abs(z))
	mulsd xmm1,xmm0			; {xmm1} contains z*(abs(z)-1)(.2447+.0663*abs(z))
	mulsd xmm0,[.quarter_pi]; {xmm0} contains pi/4*z
	subsd xmm0,xmm1			; {xmm1} contains pi/4*z-z*(abs(z)-1)(.2447+.0663*abs(z))

	test rcx,rcx			; correct based on atan(z)=pi/4-atan(1/z)
	jz .no_correction
	movsd xmm1,[.neg]		; xmm1=1000000...
	pxor xmm0,xmm1			; negated
.no_correction:
	addsd xmm0,xmm3			; add the atan2 correction value from before

.ret:
	movdqu xmm1,[rsp+0]
	movdqu xmm2,[rsp+16]
	movdqu xmm3,[rsp+32]
	add rsp,48
	pop rcx

	ret						; return

align 8	; need to align to use items below

.neg:	; sign bit
	dq 0x8000000000000000
.one:	; ~1
	dq 0x3FF0000000000000
.neg_one:	; ~-1
	dq 0xBFF0000000000000
.coeff1:	; =0.2447
	dq 0x3FCF525460AA64C3
.coeff2:	; =0.0663
	dq 0x3FB0F9096BB98C7E
.quarter_pi:	; ~.8
	dq 0x3FE921FB54442D18
.pi:	; ~3.1
	dq 0x400921FB54442D18
.neg_pi:	; ~-3.1
	dq 0xC00921FB54442D18
.half_pi:	; ~1.6
	dq 0x3FF921FB54442D18
.neg_half_pi:	; ~-1.6
	dq 0xBFF921FB54442D18
.NaN:	; ~undefined, just a random NaN value of many
	dq 0x7FF1000000000000 

%endif	
