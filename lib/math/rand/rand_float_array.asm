%ifndef RAND_FLOAT_ARRAY
%define RAND_FLOAT_ARRAY

rand_float_array:
; void rand_float_array(double {xmm0}, double {xmm1}, double* {rdi},
;			int {rsi}, int {rdx});
; Populates a {rdx}-element array starting at {rdi} with an offset of (8+{rsi})
;	bytes between elements with double-precision floating point numbers
;	such that {xmm0} <= values <= {xmm1}.

	push rax
	push rdi
	push rdx

	sub rsp,32
	movdqu [rsp+16],xmm2
	movdqu [rsp+0],xmm1

	subsd xmm1,xmm0	; range in {xmm1}

.loop:
	rdrand rax	; random 64-bit value in {rax}
	jnc .loop	; this doesn't seem to be necessary, but we will put it
			; anyway. wait for the carry flag to be set,
			; indicating we have a valid random number in {rax}	
	
	shr rax,1	; positives only
	cvtsi2sd xmm2,rax	; random 64-bit value in {xmm2}
	mulsd xmm2,[.tiny]	; convert our number with a very small increment

	mulsd xmm2,xmm1	; extend the float over the entire range
	addsd xmm2,xmm0 ; offset the float by the minimum value

	movsd [rdi],xmm2; place this element in the array
	add rdi,8	; move onto the next target address
	add rdi,rsi	

	dec rdx
	jnz .loop
	
	movdqu xmm2,[rsp+16]
	movdqu xmm1,[rsp+0]
	add rsp,32

	pop rdx
	pop rdi
	pop rax

	ret		; return

.tiny:
	dq 0x3c00000000000000	; (1/2)^63 to convert our int to float

%endif
