%ifndef PARSE_INT
%define PARSE_INT

parse_int:
; int {rax} parse_int(char* {rdi});
; 	Returns in {rax} the value of null-terminated char array starting at 
;	{rdi}.
; 	NOTE: Hex numbers must include the lower-case 
;		alphabetic characters (0xabcdef)
;	Beware: garbage in, garbage out

	push rdi
	push r8
	push rcx
	push rbx

	; get radix (base 16,10,8,2).
	movzx rbx, byte [rdi+1]
	xor rax,rax
	xor r8,r8

	cmp rbx,120 	; second digit = x
	je .hexadecimal
	cmp rbx,98 	; second digit = b
	je .binary
	cmp rbx,111 	; second digit = o
	je .octal	
	mov rcx,10 	; decimal radix
	movzx rbx, byte [rdi]
	cmp rbx,45
	jne .loop
	inc rdi
	inc r8		; flag to indicate negative	
	jmp .loop
.hexadecimal:
	mov rcx,16 	; hexadecimal radix
	add rdi,2
	jmp .loop
.octal:
	mov rcx,8 	; octal radix
	add rdi,2
	jmp .loop
.binary:
	mov rcx,2 	; binary radix
	add rdi,2
.loop:
	movzx rbx, byte [rdi]	; grab current byte
	sub rbx,48
	cmp rbx,9
	jbe .not_hex
	sub rbx,39
.not_hex:
	imul rcx
	add rax,rbx

	inc rdi
	cmp byte [rdi],0	; check if the byte is null
	jne .loop		; if not, try the next one

	test r8,r8		; handle negatives for base-10
	jz .done
	mov rcx,-1
	imul rcx

.done:
	pop rbx
	pop rcx
	pop r8	
	pop rdi

	ret

%endif
