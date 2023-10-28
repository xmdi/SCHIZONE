%ifndef IS_DIAGONAL
%define IS_DIAGONAL

is_diagonal:
; bool {rax} is_diagonal(double* {rdi}, uint {rsi}, double {xmm0});
; Returns {rax}=1 if {rsi}x{rsi} matrix at address {rdi} is diagonal.
; Values within tolerance {xmm0} are considered zero.

; Algorithm:
; Iterate over all elements checking for zeros in non-diagonal spots.

	push rdi
	push rsi
	push rcx
	push rdx
	sub rsp,16
	movdqu [rsp+0],xmm1

	cmp rsi,1
	je .yes_diagonal

	; convert rsi to indicate the byte-width between diagonal elements
	; and rdx to indicate address beyond the matrix
	mov rdx,rsi
	shl rsi,3
	imul rdx,rsi
	add rdx,rdi
	add rsi,8
	sub rdx,8

	; use rcx to track address of next diagonal element
	mov rcx,rdi
	add rcx,rsi

	; use rdi to track current element, skipping first element
	add rdi,8

; implement algorithm described above
.loop:
	; check if current element is zero within tolerance xmm0 
	movsd xmm1,[rdi]	
	pslld xmm1,1
	psrld xmm1,1
	comisd xmm1,xmm0
	ja .not_diagonal

	; move to next element, return when done
	add rdi,8
	cmp rdi,rdx
	jae .yes_diagonal

	; if current element is diagonal, skip element and set next diagonal
	cmp rdi,rcx
	jne .loop
	add rdi,8
	add rcx,rsi
	jmp .loop

.not_diagonal:
	xor rax,rax
	jmp .ret

.yes_diagonal:
	mov rax,1

.ret:
	movdqu xmm1,[rsp+0]
	add rsp,16
	pop rdx
	pop rcx
	pop rsi
	pop rdi

	ret

%endif	
