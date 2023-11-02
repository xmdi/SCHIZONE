%ifndef PLU_SOLVE
%define PLU_SOLVE

; dependencies
	%include "lib/math/lin_alg/plu_decomposition.asm"
	%include "lib/math/lin_alg/permute_matrix.asm"
	%include "lib/math/lin_alg/forward_substitution.asm"
	%include "lib/math/lin_alg/backward_substitution.asm"

plu_solve:
; void plu_solve(double* {rdi}, double* {rsi}, double* {rdx}, uint {rcx}, 
;						uint* {r8});
; Solves linear system for square {rcx}x{rcx} double-precision matrix A at {rsi}
; and {rcx}x1 right-hand-side vector b at {rdx} into resultant {rcx}x1 vector at
; {rdi}. Needs a {rcx}*8 byte array of memory allocated at {r8} to return the 
; permutation matrix P. Row-pivoting Doolittle algorithm.

	push rdi	; [rsp+32]
	push rsi	; [rsp+24]
	push rdx	; [rsp+16]
	push rcx	; [rsp+8]
	push r8		; [rsp+0]

	; perform PLU_decomposition in-place
	; so Ax=b=(PLU)x=Pb
	mov rdi,rsi	; address of A
	mov rsi,r8	; address of P (unset)
	mov rdx,rcx	; size of A matrix (# rows)
	call plu_decomposition

	; pivot RHS vector b
	mov rdi,[rsp+16]
	mov rsi,[rsp+0]
	mov rdx,[rsp+8]
	mov rcx,1
	call permute_matrix

	; forward substitution to find (Ux) from L(Ux)=b
	mov rdi,[rsp+32]
	mov rsi,[rsp+24]
	mov rdx,[rsp+16]
	mov rcx,[rsp+8]
	mov r8,2
	call forward_substitution

	; backward substitution to find x from Ux=(Ux)
	mov rdi,[rsp+32]
	mov rsi,[rsp+24]
	mov rdx,[rsp+16]
	mov rcx,[rsp+8]
	xor r8,r8
	call backward_substitution

	pop r8
	pop rcx
	pop rdx
	pop rsi
	pop rdi

	ret

%endif
