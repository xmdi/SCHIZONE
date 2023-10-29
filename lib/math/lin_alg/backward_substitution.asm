%ifndef BACKWARD_SUBSTITUTION
%define BACKWARD_SUBSTITUTION

; dependency
%include "lib/math/lin_alg/is_upper_triangular.asm"

backward_substitution:
; bool {rax} backward_substitution(double* {rdi}, double* {rsi}, double* {rdx},
;		uint {rcx}, flags {r8});
; Uses backward-substitution to solve the upper-triangular linear system with the
; square {rcx}x{rcx} matrix at address {rsi} and the right-hand {rcx}x1 vector
; at address {rdx}. Output {rcx}x1 vector of unknowns at address {rdi}.
; Clobbers input vector at {rdx}.
; Flags in {r8} as follows:
;	(low) bit-0: 1 checks triangularity before solve (sets {rax} as below)
;	bit-1: 1 sets implicit 1.0f on diagonal
; Returns {rax}=1 on matrix at {rsi} not upper triangular.
; Returns {rax}=0 on success.
; Warning: Giving a bogus system will give bogus results.

	push rdi; 104
	push rsi; 96
	push rcx
	push r9
	push r10
	push r11
	push r12
	push r13
	sub rsp,48
	movdqu [rsp+0],xmm0
	movdqu [rsp+16],xmm1
	movdqu [rsp+32],xmm2

	test r8,1
	jz .skip_checks

	; test for upper triangular input matrix
	mov rdi,rsi
	mov rsi,rcx
	movsd xmm0,[.tol]
	call is_upper_triangular
	mov rdi,[rsp+104]
	mov rsi,[rsp+96]
	test rax,rax
	jz .fail

.skip_checks:

	; if we have a valid input, proceed
	mov rax,rcx
	shl rax,3	; rax contains the byte-width of A matrix (between rows)

	; track column offset to current diagonal element (and row offset in vectors)
	mov r10,rax
	sub r10,8

	dec rcx

.next_diag:
	; bottom rightmost diag element of A matrix
	mov r12,rax
	imul r12,rcx
	add r12,rsi
	add r12,r10

	; corresponding element of b vector
	mov r9,r10
	add r9,rdx

	test r8,2
	jz .non_implicit_1
	movsd xmm0,[r9]
	jmp .x_value_set

.non_implicit_1:
	; solve corresponding element in x vector
	movsd xmm0,[r9]
	divsd xmm0,[r12]
	mov r13,r10
	add r13,rdi

.x_value_set:
	movq [r13],xmm0	; set element of x vector

	mov r11,rcx	; counter for elements above current row

	cmp r11,0
	jle .at_top_already


; move up the column and sub out vals
.go_up:
	sub r12,rax
	sub r9,8
	movsd xmm1,[r12]
	mulsd xmm1,xmm0
	movsd xmm2,[r9]
	subsd xmm2,xmm1
	movsd [r9],xmm2

	dec r11
	jnz .go_up

.at_top_already:

; go back down and left to next diagonal element

	sub r10,8
	dec rcx
	cmp rcx,0
	jge .next_diag

	xor rax,rax
	jmp .ret

.fail:
	mov rax,1

.ret:

	movdqu xmm0,[rsp+0]
	movdqu xmm1,[rsp+16]
	movdqu xmm2,[rsp+32]
	add rsp,48
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop rcx
	pop rsi
	pop rdi

	ret

.tol:
	dq 0.000000000001

%endif
