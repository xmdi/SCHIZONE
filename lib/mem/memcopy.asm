%ifndef MEMCOPY
%define MEMCOPY

memcopy:
; void memcopy(long* {rdi}, long* {rsi}, ulong {rdx});
; 	Copies {rdx} bytes from {rsi} to {rdi}.

	push rdi
	push rsi
	push rdx
	push rax

	cmp rdx,8	; if less than 8 bytes
	jb .loop_by_1	; goto smaller loop

.loop_by_8:	; copy 8 bytes at a time
	mov rax, [rsi]
	mov [rdi],rax
	add rsi,8	; goto next element of source
	add rdi,8	; goto next element of destination
	sub rdx,8
	cmp rdx,8
	jge .loop_by_8	; loop until <8 bytes remaining

; could add extra instructions here for a slight speedup

	test rdx,rdx	; if we were an exact multiple of 8
	jz .done	; skip to end

.loop_by_1:	; copy 1 byte at a time
	mov al, byte [rsi]
	mov byte [rdi], al
	inc rdi
	inc rsi
	dec rdx
	jnz .loop_by_1	; loop until 0 bytes remaining

.done:
	pop rax
	pop rdx
	pop rsi
	pop rdi

	ret

%endif
