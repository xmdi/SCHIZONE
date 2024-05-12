%ifndef EXP
%define EXP

align 16

exp:
; double {xmm0} exp(double {xmm0}, double {xmm1});
;	Computes Taylor Series approximation of e^({xmm0}) to
;	within tolerance {xmm1}, returning in {xmm0}.

	push rax
	push rcx
	push r8
	sub rsp,16
	movdqu [rsp+0],xmm2	; preserve {xmm2}

	xor r8,r8	; flag for negative input

; 	if x<=0, return NaN
;	if x==1, return 0.0f
;	otherwise use Taylor Series approximation

	pxor xmm2,xmm2	; {xmm2}=zero for comparison
	comisd xmm0,xmm2
	jae .positive_input
	inc r8	
.positive_input
	comisd xmm0,[.one]
	je .ret_zero

	; preserve other registers
	sub rsp,64
	movdqu [rsp+48],xmm3
	movdqu [rsp+32],xmm4
	movdqu [rsp+16],xmm5
	mov [rsp+8],rcx
	mov [rsp+0],rax

	; take advantage of identity ln(x)=2*ln(sqrt(x)) to relimit 0.5<x<1.5
	; (very cool trick that brings both high and low numbers into range)

	mov rax,1	; {rax} tracks a range adjustment power of 2

	; if 0.5<x<1.5, jump into Taylor Series
	comisd xmm0,[.one_point_five]
	jae .not_in_range
	comisd xmm0,[.zero_point_five]
	ja .taylor_series_prep

	; if x not in range above, compute power of 2 adjustment
.not_in_range:
	shl rax,1		; higher power of 2 adjustment required
	sqrtsd xmm0,xmm0	; {xmm0}=sqrt{x}	
	comisd xmm0,[.one_point_five]
	jae .not_in_range
	comisd xmm0,[.zero_point_five]
	jbe .not_in_range

.taylor_series_prep:
	movsd xmm2,xmm0		; {xmm2} tracks x^k
	subsd xmm2,[.one]	; expansion around ln(1+x), so adjust into the range
	pxor xmm3,xmm3		;
	subsd xmm3,xmm2		; {xmm3}=-x, multiplier between each term
	mov rcx,1		; {rcx} tracks integer denominator, k
	pxor xmm0,xmm0		; {xmm0} tracks the running sum of terms

.taylor_series_loop:
	cvtsi2sd xmm4,rcx	; convert k into double in {xmm4}
	movsd xmm5,xmm2		; {xmm5}=x^k
	divsd xmm5,xmm4		; {xmm5}=(x^k)/k
	movsd xmm4,xmm5		
	pslld xmm4,1
	psrld xmm4,1		; {xmm5}=abs((x^k)/k)
	comisd xmm4,xmm1	; compare current term against tolerance
	jbe .done			; if below, break loop
	addsd xmm0,xmm5			; otherwise, add to running sum
	inc rcx			; increment k
	mulsd xmm2,xmm3		; multiply (x^k)*(-x)
	jmp .taylor_series_loop

.done:	
	cvtsi2sd xmm2,rax	; adjust result by pre-multiplier power of 2
	mulsd xmm0,xmm2	
	
	; restore other registers
	movdqu xmm2,[rsp+64]
	movdqu xmm3,[rsp+48]
	movdqu xmm4,[rsp+32]
	movdqu xmm5,[rsp+16]
	mov rcx,[rsp+8]
	mov rax,[rsp+0]
	add rsp,80

	ret

.ret_NaN:	; return NaN
	movsd xmm0,[.NaN]
	jmp .leave	

.ret_zero:	; return 0.0f
	pxor xmm0,xmm0
.leave:
	movdqu xmm2,[rsp+0]
	add rsp,16
	ret

align 8
.zero_point_five:
	dq 0.5
.one:
	dq 1.0
.one_point_five:
	dq 1.5
.NaN:
	dq 0x7FF0000000000001 

%endif
