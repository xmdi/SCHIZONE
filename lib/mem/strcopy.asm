%ifndef STRCOPY
%define STRCOPY

strcopy:
; void strcopy(char* {rdi}, char* {rsi});
; copies null-terminated string pointed to by {rsi} to buffer at {rdi}

	push rdi
	push rsi
	push rdx

.loop:	; copy 1 byte at a time (slow but simple algorithm)
	mov dl,[rsi]
	test dl,dl
	jz .done
	mov [rdi], dl
	inc rsi
	inc rdi
	jmp .loop
	
.done:
	pop rdx
	pop rsi
	pop rdi
	ret

%endif
