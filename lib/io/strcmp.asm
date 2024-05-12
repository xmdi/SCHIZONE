%ifndef STRCMP
%define STRCMP

strcmp:
; bool {rax} strcmp(char* {rdi}, char* {rsi});
; 	Compares 2 null-terminated strings and returns 1 if they're equal.

	push rdi
	push rsi

	; precheck for nafnaf case
	mov al,byte [rdi]
	or al,byte [rsi]
	jz .success

.loop:
	mov al,byte [rdi]
	cmp byte [rsi],al
	jne .fail
	or al,byte [rsi]
	jz .success
	inc rdi
	inc rsi
	jmp .loop

.fail:
	xor rax,rax
	jmp .exit
.success:
	mov rax,1
.exit:
	pop rsi
	pop rdi

	ret

%endif
