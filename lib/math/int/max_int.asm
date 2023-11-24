%ifndef MAX_INT
%define MAX_INT

max_int:
; long {rax}, ulong {rdx} max_int(ulong {rdi}, long* {rsi});
; Identifies max of {rdi} signed longs starting at {rsi}.
; Returns max in {rax} and first index of max in {rdx}.

	push rdi
	push rsi
	push rcx

	mov rax,[rsi]
	xor rcx,rcx
	xor rdx,rdx
	cmp rdi,1
	jbe .done

.loop:
	dec rdi
	jz .done
	add rsi,8
	inc rcx
	cmp rax,[rsi]
	jle .loop
	mov rax,[rsi]
	mov rdx,rcx
	jmp .loop

.done:
	pop rcx
	pop rsi
	pop rdi
	ret		; return

%endif
