%ifndef COPY_DIAGONAL
%define COPY_DIAGONAL

copy_diagonal:
; void copy_diagonal(double* {rdi}, double* {rsi}, uint {rdx});
; 	Copies diagonal of {rdx}x{rdx} matrix at address {rsi} to matrix 
; 	at address {rdi}. Overwrites the diagonals of the destination matrix.

	push rdi
	push rsi
	push rax
	push rdx
	push rcx

	mov rcx,rdx
	shl rcx,3
	imul rdx,rcx	
	add rdx,rsi	; {rsi} points beyond source matrix
	add rcx,8	; {rcx} contains byte-distance between diagonal elements

.loop:
	mov rax,[rsi]
	mov [rdi],rax
	add rdi,rcx
	add rsi,rcx
	cmp rsi,rdx
	jb .loop

	pop rcx
	pop rdx
	pop rax
	pop rsi
	pop rdi

	ret	

%endif
