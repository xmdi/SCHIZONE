%ifndef PLU_DECOMPOSITION
%define PLU_DECOMPOSITION

; dependencies:
%include "lib/math/vector/max_abs_float.asm"
%include "lib/math/lin_alg/swap_matrix_rows.asm"

plu_decomposition:
; void plu_decomposition(double* {rdi}, uint* {rsi}, uint {rdx});
; Uses a row-pivoting Doolittle algorithm to deconstruct the {rdx}x{rdx}
; matrix at address {rdi} into lower- and upper-triangular matrices stored
; together in the original memory space and a {rdx}x1 permutation vector 
; at {rsi}.

;	see https://scs.org/wp-content/uploads/2017/06/49_Final_Manuscript.pdf

	; algorithm:
	;	for k=0:(n-1)
	;		<reorder the rows in A such that A(k,k) is max(abs(A(k:N,k)))
	;			and also record this effect on the permutation matrix>
	;		for i=(k+1):n
	;			A(i,k)=A(i,k)/A(k,k); <-- that's why pivotless is a bad idea
	;			for j=(k+1):n
	;				A(i,j)=A(i,j)-A(i,k)*A(k,j);
	;			end
	;		end
	;	end

	; The permutation vector at {rsi} has the form:
	; [0,1,2,3,4...{rdx}]
	; This doesn't need to be set before the function is called;
	; it will be set by this routine.

	push rax
	push rbx
	push rcx
	push rdx
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push r14
	push r15
	sub rsp,48
	movdqu [rsp+0],xmm0 
	movdqu [rsp+16],xmm1 
	movdqu [rsp+32],xmm2

	; {rdi} points to the start of the matrix A
	; {rsi} points to the start of the permutation vector
	; {rbx} contains the number of rows and columns in A
	mov rbx,rdx
	; {rdx} contains the byte-width of rows in A
	shl rdx,3


	; set the permutation vector
	mov r8,rsi
	xor rax,rax
.create_permutation_vector_loop:
	mov [r8],rax
	inc rax
	add r8,8
	cmp rax,rbx
	jb .create_permutation_vector_loop


			; for k=0:n-1
	xor rcx,rcx	;	track k in {rcx}
.loop_k:
;		<reorder the rows in A such that A(k,k) is max(abs(A(:,k)))
;			and also record this effect on the permutation matrix>

	push rdi
	push rsi
	push rdx
	push rcx

	mov r8,rdx
	imul r8,rcx
	add rdi,r8
	shl rcx,3
	add rdi,rcx	; {rdi}=address of A(k,k)
	mov r15,rdi
	mov rsi,rdx
	sub rsi,8
	sub rdx,rcx
	shr rdx,3	; {rdx}=N-k
	call max_abs_float

	; {rax} contains row index of the max(abs(A(k:N,k))) relative to A(k,:)

	pop rcx
	pop rdx
	pop rsi
	pop rdi

	; possible TODO: only send the lower rows into the pivot_matrix routine.

	add rax,rcx	; {rax} contains absolute row index of max(abs(A(k:N,k)))

	; swap the k'th element of the permutation vector with the {rax}'th

	shl rcx,3
	shl rax,3
	mov r8,[rsi+rax]
	mov r9,[rsi+rcx]
	mov [rsi+rax],r9
	mov [rsi+rcx],r8
	shr rcx,3
	shr rax,3

	; swap the k'th row of matrix A with the {rax}'th row

	push rdi
	push rsi
	push rdx
	push rcx

	mov rsi,rdi
	mov r8,rdx
	imul r8,rcx
	add rdi,r8	; {rdi}=A(k,1)
	mov r8,rdx
	imul r8,rax
	add rsi,r8	; {rsi}=A({rax},1)
	shr rdx,3	; {rdx}=N
	call swap_matrix_rows
	
	pop rcx
	pop rdx
	pop rsi
	pop rdi

;	for i=(k+1):n
	mov r8,rcx	;	track i in {r8}
	inc r8

	cmp r8,rbx	;	test if condition is violated on first iteration
	jge .skip_loop_i

.loop_i:

	mov r15,rcx
	shl r15,3	;	{r15} temporarily tracks the byte-offset to the k'th column

	mov r10,r8	
	imul r10,rdx
	add r10,rdi
	mov r12,r10	;	{r12} points to A(i,0)
	add r10,r15	;	{r10} points to A(i,k)

	mov r11,rcx	
	imul r11,rdx
	add r11,rdi
	mov r13,r11	;	{r13} points to A(k,0)
	add r11,r15	;	{r11} points to A(k,k)


;		A(i,k)=A(i,k)/A(k,k); <-- thats why pivotless is a bad idea
	movsd xmm0,[r10]
	divsd xmm0,[r11]
	movsd [r10],xmm0	; keep A(i,k) in xmm0 for later


;			for j=(k+1):n
	mov r9,rcx	;	track j in {r9}	
	inc r9

	cmp r9,rbx	;	test if condition is violated on first iteration
	jge .skip_loop_j

.loop_j:

	mov r14,r9
	shl r14,3
	mov r15,r14
	add r14,r12	;	{r14} points to A(i,j)
	add r15,r13	;	{r15} points to A(k,j)

;				A(i,j)=A(i,j)-A(i,k)*A(k,j);
	movsd xmm1,xmm0
	mulsd xmm1,[r15]
	movsd xmm2,[r14]
	subsd xmm2,xmm1
	movsd [r14],xmm2

	inc r9
	cmp r9,rbx
	jb .loop_j	; loop thru j until done

.skip_loop_j:

	inc r8
	cmp r8,rbx
	jb .loop_i	; loop thru i until done

.skip_loop_i:

	inc rcx
	mov r15,rbx	; these 3 lines basically skip the last submatrix
	dec r15
	cmp rcx,r15
	jb .loop_k	; loop thru k until done

	movdqu xmm0,[rsp+0]
	movdqu xmm1,[rsp+16]
	movdqu xmm2,[rsp+32]
	add rsp,48
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rdx
	pop rcx
	pop rbx
	pop rax
	ret

%endif
