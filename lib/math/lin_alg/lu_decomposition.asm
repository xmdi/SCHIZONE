%ifndef LU_DECOMPOSITION
%define LU_DECOMPOSITION

lu_decomposition:
; void lu_decomposition(double* {rdi}, uint {rsi});
; Uses a (pivotless) Doolittle algorithm to deconstruct the square {rsi}x{rsi}
; matrix at address {rdi} into lower- and upper-triangular matrices stored
; together in the original memory space.

	push rdx
	push rcx
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

	; algorithm:
	;   for k=0:(n-1)
	;      for i=(k+1):n
	;         A(i,k)=A(i,k)/A(k,k); <-- that's why pivotless is a bad idea
	;         for j=(k+1):n
	;	     A(i,j)=A(i,j)-A(i,k)*A(k,j);
	;	  end
	;      end
	;   end

	; {rdi} points to the start of the matrix A
	; {rsi} contains the number of rows and columns in A
	mov rdx,rsi
	shl rdx,3
	; {rdx} contains the byte-width of rows in A
	
; for k=0:n-1
	xor rcx,rcx	;	track k in {rcx}
.loop_k:
;	for i=(k+1):n
	mov r8,rcx	;	track i in {r8}
	inc r8

	cmp r8,rsi	;	test if condition is violated on first iteration
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

	cmp r9,rsi	;	test if condition is violated on first iteration
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
	cmp r9,rsi
	jb .loop_j	; loop thru j until done

.skip_loop_j:

	inc r8
	cmp r8,rsi
	jb .loop_i	; loop thru i until done

.skip_loop_i:

	inc rcx
	mov r15,rsi
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
	pop rcx
	pop rdx

	ret

%endif
