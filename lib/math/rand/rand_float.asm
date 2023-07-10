%ifndef RAND_FLOAT
%define RAND_FLOAT

rand_float:
; double {xmm0} rand_float(double {xmm0}, double {xmm1});
; 	Returns in {xmm0} a random double-precision floating point value such
;	that {xmm0 (input)} <= {xmm0 (output)} <= {xmm1}.

	sub rsp,40
	movdqu [rsp+24],xmm2
	movdqu [rsp+8],xmm1
	mov [rsp+0],rax	

.loop:
	rdrand rax	; random 64-bit value in {rax}
	jnc .loop	; this doesn't seem to be necessary, but we will put it
			; anyway. wait for the carry flag to be set,
			; indicating we have a valid random number in {rax}	
	
	shr rax,1	; positives only
	subsd xmm1,xmm0	; range in {xmm1}
	cvtsi2sd xmm2,rax	; random 64-bit value in {xmm2}
	mulsd xmm2,[.tiny]	; convert our number with a very small increment

	mulsd xmm1,xmm2	; extend the float over the entire range
	addsd xmm0,xmm1 ; offset the float by the minimum value

	movdqu xmm2,[rsp+24]
	movdqu xmm1,[rsp+8]
	mov rax,[rsp+0]
	add rsp,40

	ret		; return

.tiny:
	dq 0x3c00000000000000	; (1/2)^63 to convert our int to float

%endif
