%ifndef PERMUTE_MATRIX
%define PERMUTE_MATRIX

permute_matrix:
; void permute_matrix(double* {rdi}, ulong* {rsi}, uint {rdx}, uint {rcx});
; Permutes rows of {rdx}x{rcx} matrix beginning at address {rdi} into the
; order specified in {rdx}x1 permutation vector at {rsi} which is
; preserved.

	; Permutation vector has a form like: [3, 1, 2, 4, 0, ... ]

	; algorithm:
	;	for(int i=0; i<(n-1); i++){
	;		index=P(i); %get index of pointed element
	;		while(index<i) %iterate until we are not left of the index
	;			index=P[index];
	;		end
	;		%swap elements in array
	;		temp=A(i);
	;		A(i)=A(index);
	;		A(index)=temp;
	;	end

	push rax
	push rcx
	push r8
	push r9
	push r10
	push r11
	sub rsp,32
	movdqu [rsp+0],xmm0	
	movdqu [rsp+16],xmm1

	shl rcx,3	; {rcx} contains the byte-width of the input matrix
	xor rax,rax ; {rax} tracks current row of the permutation matrix
	mov r8,rdi	; {r8} tracks the address of row {rax} in the input matrix

	; we start at the {rax}=0th element

.outer_loop:	; iterate through the rows of the permutation matrix
	
	; get index contained at pointed element
	mov r9,[rsi+8*rax]	; {r9} tracks desired row of values
	
	cmp r9,rax			; test if index<i
	jge .skip_inner_loop

.inner_loop:	; iterate until we are not left of the index
	
	mov r9,[rsi+8*r9]	; index=P[index]
	
	cmp r9,rax			; test if index<i
	jb .inner_loop

.skip_inner_loop:

	mov r10,r9
	imul r10,rcx		
	add r10,rdi ; {r10} tracks address of row {r9} of input matrix

	; now we swap elements of the input matrix, 
	; column by column (between rows {rax} & {r9})

	xor r11,r11	; {r11} tracks column in input matrix
	
.next_column:	; swap rows in input matrix

	movsd xmm0,[r8+r11]
	movsd xmm1,[r10+r11]
	movsd [r8+r11],xmm1
	movsd [r10+r11],xmm0

	add r11,8
	cmp r11,rcx
	jb .next_column	; swap 2 elements in next column

	add r8,rcx
	inc rax
	cmp rax,rdx
	jb .outer_loop	; go to next row

	movdqu xmm0,[rsp+0]
	movdqu xmm1,[rsp+16]
	add rsp,32
	pop r11
	pop r10
	pop r9
	pop r8
	pop rcx
	pop rax

	ret

%endif
