%ifndef GETENV
%define GETENV

getenv:
;  char* {rax} getenv(char* {rdi}, void* {rsi});
; 	Searches stack for null-terminated environment variable starting at
;	{rdi} and returns address of null-terminated entry at {rax}. Program 
;	entry argc address passed in {rsi}. Returns NULL {rax} on fail.

	push rsi
	push rdx
	push rcx

	mov rax,[rsi]
	add rax,2
	shl rax,3
	add rsi,rax	; {rsi} points to first environment variable address

.outer_loop:
	mov rcx,rdi
	mov rdx,[rsi]

.inner_loop:
	cmp byte [rcx],0
	je .success
	
	mov al,byte [rcx]
	cmp byte [rdx],al
	jne .inner_loop_fail

	inc rcx
	inc rdx
	jmp .inner_loop

.inner_loop_fail:
	add rsi,8
	cmp qword [rsi],0
	je .fail
	jmp .outer_loop

.fail:
	xor rax,rax
	jmp .exit

.success:
	mov rax,rdx
	inc rax

.exit:
	pop rcx
	pop rdx
	pop rsi

	ret

%endif
