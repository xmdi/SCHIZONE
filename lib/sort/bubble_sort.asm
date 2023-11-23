%ifndef BUBBLE SORT
%define BUBBLE_SORT

bubble_sort:
; void bubble_sort(void* {rdi}, uint {rsi});
;	Sorts {rsi} elements at {rdi} in ascending order.

	cmp rsi,1
	jle .ret

	push rdi
	push rax
	push rcx

	xor rcx,rcx
.loop:
	mov rax,[rdi]
	cmp rax,[rdi+8]
	jle .no_swap
.swap:
	push [rdi+8]
	mov [rdi+8],rax
	pop [rdi]
	cmp rcx,0
	je .no_swap
	dec rcx
	jmp .check_loop
.no_swap:
	inc rcx
.check_loop:
	cmp rcx,rsi
	jb .loop

	pop rcx
	pop rax
	pop rdi
.ret:
	ret

%endif
