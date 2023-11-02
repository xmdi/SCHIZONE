%ifndef LU_SOLVE
%define LU_SOLVE

; dependencies
	%include "lib/math/lin_alg/lu_decomposition.asm"
	%include "lib/math/lin_alg/forward_substitution.asm"
	%include "lib/math/lin_alg/backward_substitution.asm"

lu_solve:
; void {rax} lu_solve(double* {rdi}, double* {rsi}, double* {rdx}, uint {rcx});
; Solves linear system for square {rcx}x{rcx} double-precision matrix A at {rsi}
; and {rcx}x1 right-hand-side vector b at {rdx} into resultant {rcx}x1 vector at

	push r8	
	push rdi
	push rsi

	; perform LU_decomposition in-place
	; so Ax=b=(LU)x=b
	mov rdi,rsi	; address of A
	mov rsi,rcx	; size of A matrix (# rows)
	call lu_decomposition

	pop rsi
	pop rdi

	; forward substitution to find (Ux) from L(Ux)=b
	mov r8,2
	call forward_substitution

	; backward substitution to find x from Ux=(Ux)
	xor r8,r8
	call backward_substitution

	pop r8
	ret

%endif
