%ifndef STRSPLIT
%define STRSPLIT

strsplit:
; void strsplit(char* {rdi}, char* {rsi}, char {dl});
; 	Copies string (terminated by splitting character in {dl} 
;	pointed to by {rsi} to buffer at {rdi}.

	push rdi
	push rsi
	push rax

.loop:	; copy 1 byte at a time (slow but simple algorithm)
	mov al,[rsi]
	cmp al,dl
	je .done
	mov [rdi], al
	inc rsi
	inc rdi
	jmp .loop
	
.done:
	pop rax
	pop rsi
	pop rdi
	ret

%endif
