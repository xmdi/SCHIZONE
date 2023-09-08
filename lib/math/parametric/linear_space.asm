%ifndef LINEAR_SPACE
%define LINEAR_SPACE

linear_space:
; bool {rax} linear_space(double* {rdi}, long {rsi}, ulong {rdx}
;			double {xmm0}, double {xmm1});
; Writes a linear-spaced array of float values to a memory desination.
; 	{rdi} points to first address of destination array
; 	{rsi} contains extra stride between elements
; 	{rdx} contains number of elements
; 	{xmm0} contains first value (low 8-byte double)
; 	{xmm1} contains last value (low 8-byte double)
;	Returns {rax}=1 on error, 0 otherwise.

	; check for positive {rdx}
	test rdx,rdx
	jz .error
	
	push rcx
	push rdx
	sub rsp,48
	movdqu [rsp+0],xmm0
	movdqu [rsp+16],xmm1
	movdqu [rsp+32],xmm2

	; compute increment between values
	mov rcx,rdx
	dec rcx
	cvtsi2sd xmm2,rcx
	subsd xmm1,xmm0
	divsd xmm1,xmm2		; increment in {xmm1}

	; populate memory with values
.loop:
	movq [rdi],xmm0
	add rdi,rsi
	add rdi,8
	addsd xmm0,xmm1
	dec rdx
	jnz .loop	; fall out when done

	movdqu xmm2,[rsp+32]
	movdqu xmm1,[rsp+16]
	movdqu xmm0,[rsp+0]
	add rsp,48
	pop rdx
	pop rcx
	
	; set {rax}=0 and return
	xor rax,rax
	ret

.error:	
	; set {rax}=1 and return
	mov rax,1
	ret

%endif	
