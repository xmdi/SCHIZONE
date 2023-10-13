%ifndef ARCTANGENT
%define ARCTANGENT

arctangent:
; double {xmm0} arctangent(double {xmm0}, double {xmm1}, double {xmm2});
; computes Taylor series polynomial approximation of atan({xmm0}/{xmm1})
; (Note the order!, y/x, first input over second input!)
; to within tolerance {xmm2}, return value in {xmm0}

; this routine might be referred to as "atan2" if I was a boomer

	push rcx
	sub rsp,112
	movdqu [rsp+0],xmm1
	movdqu [rsp+16],xmm3
	movdqu [rsp+32],xmm4
	movdqu [rsp+48],xmm8
	movdqu [rsp+64],xmm9
	movdqu [rsp+80],xmm10
	movdqu [rsp+96],xmm11

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
	; put the atan2 correction value into {xmm3} for later
		;+0.0 for x>0
		;+pi for x<0, y>=0
		;-pi for x<0, y<0
	comisd xmm1,xmm3
	ja .start_taylor_series ; if x>0, {xmm3}=0.0, then start series
	comisd xmm0,xmm3
	jb .neg_y
.pos_y:	; if x<0 & y>=0, {xmm3}=+pi, then start series
	movsd xmm3,[.pi]
	jmp .start_taylor_series
.neg_y:	; if x<0 & y<0, {xmm3}=-pi, then start series
	movsd xmm3,[.neg_pi]

.start_taylor_series:

	; we will apply atan(z)=pi/4-atan(1/z) to reduce the range
	xor rcx,rcx		; {rcx} flag tracks if we were originally out of range of (-1,1) on z
	movsd xmm8,xmm0
	divsd xmm0,xmm1		; start by assigning z=y/x
	comisd xmm0,[.one]
	ja .invert_down
	comisd xmm0,[.neg_one]
	ja .go
.invert_up:
	inc rcx
	movsd xmm0,xmm8
	divsd xmm1,xmm0
	movsd xmm0,xmm1
	addsd xmm3,[.neg_half_pi]
	jmp .go
.invert_down:
	inc rcx
	movsd xmm0,xmm8
	divsd xmm1,xmm0
	movsd xmm0,xmm1
	addsd xmm3,[.half_pi]

.go:

; get some stuff ready
	movsd xmm10,xmm0		; xmm10=x
	mulsd xmm10,xmm10		; xmm10=x*x
	movsd xmm8,[.neg]		; xmm8=1000000...
	pxor xmm10,xmm8			; xmm10=-x*x
							; track current power of x (x^k) in xmm0
	pxor xmm8,xmm8			; track polynomial sum in xmm8
	movsd xmm1,[.one]		; track denominator in xmm1, start at 1.0
	movsd xmm4,[.two]		; keep 2.0 in a register to add to denominator each iteration

; compute taylor series approximation (very slow and bad)
.loop:
	movsd xmm11,xmm0		; current x^k in xmm11
	divsd xmm11,xmm1		; divide by current factorial ; TODO: can take this out of the first iteration if you want, since xmm1=1
	movsd xmm9,xmm11		; copy current term into xmm9
	pslld xmm9,1
	psrld xmm9,1
	comisd xmm9,xmm2		; compare current term against tolerance
	jbe .done				; if we are below tolerance, exit loop
	addsd xmm8,xmm11		; otherwise, add current term to running sum
	mulsd xmm0,xmm10		; multiply current power of x by (-x*x)
	addsd xmm1,xmm4			; add 2.0 to denominator
	jmp .loop				; keep looping

.done:
	movsd xmm0,xmm8			; put sum in xmm0
	test rcx,rcx			; correct based on atan(z)=pi/4-atan(1/z)
	jz .no_correction
	movsd xmm1,[.neg]		; xmm1=1000000...
	pxor xmm0,xmm1			; negated
.no_correction:
	addsd xmm0,xmm3			; add the atan2 correction value from before

.ret:
	movdqu xmm1,[rsp+0]
	movdqu xmm3,[rsp+16]
	movdqu xmm4,[rsp+32]
	movdqu xmm8,[rsp+48]
	movdqu xmm9,[rsp+64]
	movdqu xmm10,[rsp+80]
	movdqu xmm11,[rsp+96]
	add rsp,112
	pop rcx

	ret						; return

align 8	; need to align to use items below

.neg:	; sign bit
	dq 0x8000000000000000
.one:	; ~1
	dq 0x3FF0000000000000
.neg_one:	; ~-1
	dq 0xBFF0000000000000
.two:	; ~2
	dq 0x4000000000000000
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
