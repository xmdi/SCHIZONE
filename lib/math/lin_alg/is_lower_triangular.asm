%ifndef IS_LOWER_TRIANGULAR
%define IS_LOWER_TRIANGULAR

is_lower_triangular:
; bool {rax} is_lower_triangular(double* {rdi}, uint {rsi}, double {xmm0});
; Returns {rax}=1 if {rsi}x{rsi} matrix at address {rdi} is lower-triangular.
; Values within tolerance {xmm0} are considered zero.

; Algorithm:
; Start at [0,N-1] element and go back horizontally up until diagonal,
; checking for zeros. Move down one row at a time repeating above until 
; we exceed the memory of the matrix.

	push rdi
	push rsi
	push rcx
	push rdx
	sub rsp,16
	movdqu [rsp+0],xmm1

	cmp rsi,1
	je .yes_lower_triangular

	; convert rsi to track the byte-width of matrix row
	shl rsi,3

	; use rcx to track byte offset for current column
	mov rcx,rsi
	sub rcx,8

	; use rdx to track current byte offset to current diagonal element
	xor rdx,rdx

	; use rdi to track address of [i,0] element, starting at i=0

; implement algorithm described above
.loop:
	; check if current element is zero within tolerance xmm0 
	movsd xmm1,[rdi+rcx]	
	pslld xmm1,1
	psrld xmm1,1
	comisd xmm1,xmm0
	ja .not_lower_triangular

	; move to next column, up until (not including) diagonal
	sub rcx,8
	cmp rcx,rdx
	ja .loop

	; check if we are at the last row
	add rdx,8
	test rdx,rsi
	jge .yes_lower_triangular

	; move to next row
	mov rcx,rsi
	sub rcx,8
	add rdi,rsi
	jmp .loop

.not_lower_triangular:
	xor rax,rax
	jmp .ret

.yes_lower_triangular:
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
