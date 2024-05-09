%ifndef EVALUATE_POSTFIX_STRING
%define EVALUATE_POSTFIX_STRING

%include "lib/io/parse_float.asm"

%include "lib/math/expressions/parse/stack_math_ops.asm"

evaluate_postfix_string:
; double {xmm0}, bool {rax} evaluate_postfix_string(char* {rdi});
; Evaluates the null-terminated postfix expression string beginning at {rdi}.
; Result of calculation in {xmm0} if null {rax}. Otherwise, {rax}=1 on fail.

	push rdi
	push rbp
	mov rbp,rsp

; tokenize. aka split on space char (' ') and after numeric

.loop:
	
	cmp byte [rdi],0 ; null byte
	je .end

	cmp byte [rdi],32 ; " "
	jne .valid
	inc rdi
	jmp .skip	

.valid:
	; check if byte @ [rdi] is numeric
	cmp byte [rdi],45 ; = "-"
	jne .not_neg_symbol
	cmp byte [rdi+1],46 ; = "."
	je .sneak_in_minus_sign
	cmp byte [rdi+1],48 ; < "0"
	jl .sneak_in_minus_sign
	cmp byte [rdi+1],57 ; > "9"
	jg .sneak_in_minus_sign
	jmp .numeric
.not_neg_symbol:
	cmp byte [rdi],46 ; < "."
	jl .not_numeric
	cmp byte [rdi],57 ; > "9"
	jg .not_numeric
	cmp byte [rdi],47 ; /
	je .not_numeric
.numeric:

	call parse_float

	mov rdi,rax
	
	sub rsp,8
	movq [rsp+0],xmm0
	jmp .loop

.not_numeric:
	cmp byte [rdi],43 ; "+"
	jne .not_plus
	call stack_math_ops.addition
	add rsp,8
	inc rdi
	jmp .skip	
.not_plus:
	cmp byte [rdi],45 ; "-"
	jne .not_minus
.sneak_in_minus_sign:
	call stack_math_ops.subtraction
	add rsp,8
	inc rdi
	jmp .skip	
.not_minus:
	cmp byte [rdi],42 ; "*"
	jne .not_multiplication
	call stack_math_ops.multiplication
	add rsp,8
	inc rdi
	jmp .skip	
.not_multiplication:
	cmp byte [rdi],47 ; "/"
	jne .not_division
	call stack_math_ops.division
	add rsp,8
	inc rdi
	jmp .skip	
.not_division:
	cmp byte [rdi],47 ; "^"
	jne .not_exponent
	call stack_math_ops.exponent
	add rsp,8
	inc rdi
	jmp .skip
.not_exponent:


.skip:
	jmp .loop

.end:

	mov rdi,rsp
	sub rdi,rbp
	cmp rdi,-8
	je .not_retarded
	mov rax,1
	jmp .quit
.not_retarded:
	xor rax,rax
	movsd xmm0,[rsp+0]
.quit:
	mov rsp,rbp
	pop rbp
	pop rdi

	ret




%endif	
