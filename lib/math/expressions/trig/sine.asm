%ifndef SINE
%define SINE

align 64
sine:
; double {xmm0} sine(double {xmm0}, double {xmm1});
; computes Taylor series polynomial approximation of sine({xmm0})
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

; get some stuff ready
.get_ready:
	movsd xmm10,xmm0		; xmm10=x
	mulsd xmm10,xmm10		; xmm10=x*x
	movsd xmm8,[.neg]		; xmm8=1000000...
	pxor xmm10,xmm8			; xmm10=-x*x
							; track current power of x (x^k) in xmm0
	pxor xmm8,xmm8			; track polynomial sum in xmm8
	mov rcx,1				; track polynomial order in rcx
	mov rdx,1				; track factorial denominator in rdx

; compute taylor series approximation (very slow and bad)
.loop:
	cvtsi2sd xmm9,rdx		; convert factorial denominator to float
	movsd xmm11,xmm0		; current x^k in xmm11
	divsd xmm11,xmm9		; divide by current factorial
	movsd xmm9,xmm11		; copy current term into xmm9	
	pslld xmm9,1
	psrld xmm9,1
	comisd xmm9,xmm1		; compare current term against tolerance
	jbe .done				; if we are below tolerance, exit loop
	addsd xmm8,xmm11		; otherwise, add current term to running sum
	inc rcx					; skip "even" terms of polynomial
	imul rdx,rcx			; ...but computer integer factorial denominator
	inc rcx					; ...at intermediate value of rcx 
	imul rdx,rcx			; ...and keep track in rdx
	mulsd xmm0,xmm10		; multiply current power of x by (-x*x)
	jmp .loop				; keep looping

.done:
	movsd xmm0,xmm8			; return sum in xmm0

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
