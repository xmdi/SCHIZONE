%ifndef STRLEN
%define STRLEN

strlen:
; int {rax} strlen(char* {rdi});
; 	Returns in {rax} the length of null-terminated char array starting at 
;	{rdi}.

	mov rax,-1		; set strlen counter to -1

.loop:
	inc rax			; increase the counter by 1
	cmp byte [rdi+rax],0	; check if the byte is null
	jne .loop		; if not, try the next one

	ret

%endif
