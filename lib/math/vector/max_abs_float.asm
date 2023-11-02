%ifndef MAX_ABS_FLOAT
%define MAX_ABS_FLOAT

max_abs_float:
; double {xmm0} long {rax} max_abs_float(double* {rdi}, long {rsi}, long {rdx});
; Returns in {xmm0} the maximum (by absolute value) 8-byte double from the set 
; starting at address {rdi} with extra stride {rsi} and {rdx} elements.
; Returns ID of first maxima in {rax}, -1 on failure.

	push rdi
	push rdx
	push rcx
	sub rsp,16
	movdqu [rsp+0],xmm1

	; check if at least 1 element
	cmp rdx,1
	jl .fail

	; initialize counter
	xor rcx,rcx

	; set abs max to the zeroth element
	xor rax,rax
	movsd xmm0, qword [rdi]	

	pslld xmm0,1
	psrld xmm0,1
	
	; check if we had only 1 element
	cmp rdx,1
	je .ret

	dec rdx	; we skip the first one in our loop

.loop:
	inc rcx
	add rdi,8		; go to next element
	add rdi,rsi
	movsd xmm1, qword [rdi]	; absolute value
	pslld xmm1,1
	psrld xmm1,1
	comisd xmm0,xmm1	; compare element with max
	jae .not_max
	movsd xmm0,xmm1		; new max value
	mov rax,rcx		; new max ID
.not_max:
	dec rdx
	jnz .loop		; continue until done
.ret:

	movdqu xmm1,[rsp+0]
	add rsp,16	
	pop rcx
	pop rdx
	pop rdx

	ret

.fail:
	mov rax,-1
	pxor xmm0,xmm0
	jmp .ret

%endif
