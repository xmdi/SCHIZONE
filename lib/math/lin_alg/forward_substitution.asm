%ifndef FORWARD_SUBSTITUTION
%define FORWARD_SUBSTITUTION

; dependency
%include "lib/math/lin_alg/is_lower_triangular.asm"

forward_substitution:
; bool {rax} forward_substitution(double* {rdi}, double* {rsi}, double* {rdx},
;		uint {rcx}, flags {r8});
; Uses forward-substitution to solve the lower-triangular linear system with the
; square {rcx}x{rcx} matrix at address {rsi} and the right-hand {rcx}x1 vector
; at address {rdx}. Output {rcx}x1 vector of unknowns at address {rdi}.
; Clobbers input vector at {rdx}.
; Flags in {r8} as follows:
;	(low) bit-0: 1 checks triangularity before solve (sets {rax} as below)
;	bit-1: 1 sets implicit 1.0f on diagonal
; Returns {rax}=1 on matrix at {rsi} not lower triangular.
; Returns {rax}=0 on success.
; Warning: Giving a bogus system will give bogus results.

	push rdi; 88
	push rsi; 80
	push r9
	push r10
	push r11
	push r12
	sub rsp,48
	movdqu [rsp+0],xmm0
	movdqu [rsp+16],xmm1
	movdqu [rsp+32],xmm2

	test r8,1
	jz .skip_checks

	; test for lower triangular input matrix
	mov rdi,rsi
	mov rsi,rcx
	movsd xmm0,[.tol]
	call is_lower_triangular
	mov rdi,[rsp+88]
	mov rsi,[rsp+80]
	test rax,rax
	jz .fail

.skip_checks:

	; if we have a valid input, proceed
	mov rax,rcx
	shl rax,3	; rax contains the byte-width of A matrix (between rows)

	; {rdi} points to current element of x vector
	xor r10,r10	; {r10} tracks current diag number

.next_diag:
	; ith row of A matrix
	mov r11,r10
	shl r11,3
	mov r12,rax
	imul r12,r10
	add r12,r11
	add r12,rsi

	; corresponding element of b vector
	mov r9,r10
	shl r9,3
	add r9,rdx

	test r8,2
	jz .non_implicit_1
	movsd xmm0,[r9]
	jmp .x_value_set

.non_implicit_1:
	; solve corresponding element in x vector
	movsd xmm0,[r9]
	divsd xmm0,[r12]

.x_value_set:
	movq [rdi],xmm0	; set element of x vector

	mov r11,rcx	; counter for elements below current row
	sub r11,r10
	dec r11
	cmp r11,0
	jle .at_bottom_already

; move down the column and sub out vals
.go_down:
	add r12,rax
	add r9,8
	movsd xmm1,[r12]
	mulsd xmm1,xmm0
	movsd xmm2,[r9]
	subsd xmm2,xmm1
	movsd [r9],xmm2

	dec r11
	jnz .go_down

.at_bottom_already:
; go back up and right to next diagonal element

	add rdi,8
	inc r10
	cmp r10,rcx
	jb .next_diag

	xor rax,rax
	jmp .ret

.fail:
	mov rax,1

.ret:

	movdqu xmm0,[rsp+0]
	movdqu xmm1,[rsp+16]
	movdqu xmm2,[rsp+32]
	add rsp,48
	pop r12
	pop r11
	pop r10
	pop r9
	pop rsi
	pop rdi

	ret

.tol:
	dq 0.000000000001

%endif
