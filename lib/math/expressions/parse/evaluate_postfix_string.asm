%ifndef EVALUATE_POSTFIX_STRING
%define EVALUATE_POSTFIX_STRING

; TODO add leading decimal as valid input to parse_float

%include "lib/io/parse_float.asm"

evaluate_postfix_string:
; double {xmm0}, bool {rax} evaluate_postfix_string(char* {rdi});
; Evaluates the null-terminated postfix expression string beginning at {rdi}.
; Result of calculation in {xmm0} if null {rax}. Otherwise, {rax}=1 on fail.

%if 0

	; how should we do our stack?
	
	; dq float
	; dq "what follows this is a float"
	; dq float
	; dq "what follows this is a float"
	; dq operator function pointer
	; dq "what follows this is an operator" <----{rsp}

%endif

	push rdi
	push rbp
	mov rbp,rsp
	xor rbx,rbx

; tokenize. aka split on space char (' ') and after numeric

.loop:
	
	; check if byte @ [rdi] is numeric
	cmp byte [rdi],45 ; < "-"
	jl .not_numeric
	cmp byte [rdi],57 ; > "9"
	jg .not_numeric
	cmp byte [rdi],47 ; /
	je .not_numeric
	call parse_float
	
;	sub rsp,8
;	movq [rsp+0],xmm0
;	push rbx	

.not_numeric:

;	jmp .loop

	xor rax,rax

	mov rsp,rbp
	pop rbp
	pop rdi

	ret

%endif	
