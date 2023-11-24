%ifndef MAX_INT
%define MAX_INT

max_int:
; long {rax}, ulong {rdx} max_int(ulong {rdi}, long* {rsi}, long {rdx});
; Identifies max of {rdi} signed longs starting at {rsi}.
; Additional offset between elements in {rdx}.
; Returns max in {rax} and first index of max in {rdx}.

	push rdi
	push rsi
	push rcx
	push r8

	mov r8,rdx
	mov rax,[rsi]
	xor rcx,rcx
	xor rdx,rdx
	cmp rdi,1
	jbe .done

.loop:
	dec rdi
	jz .done
	add rsi,8
	add rsi,r8
	inc rcx
	cmp rax,[rsi]
	jle .loop
	mov rax,[rsi]
	mov rdx,rcx
	jmp .loop

.done:
	pop r8
	pop rcx
	pop rsi
	pop rdi
	ret		; return

%endif
