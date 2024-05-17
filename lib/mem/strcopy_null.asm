%ifndef STRCOPY_NULL
%define STRCOPY_NULL

strcopy_null:
; void strcopy_null(char* {rdi}, char* {rsi});
; Copies null-terminated string pointed to by {rsi} to buffer at {rdi},
; 	followed by a null-byte.

	push rdi
	push rsi
	push rdx

.loop:	; copy 1 byte at a time (slow but simple algorithm)
	mov dl,[rsi]
	test dl,dl
	jz .done
	mov [rdi],dl
	inc rsi
	inc rdi
	jmp .loop
	
.done:
	mov [rdi],dl
	pop rdx
	pop rsi
	pop rdi
	ret

%endif
