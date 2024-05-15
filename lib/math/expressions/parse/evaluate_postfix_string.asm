%ifndef EVALUATE_POSTFIX_STRING
%define EVALUATE_POSTFIX_STRING

%include "lib/io/parse_float.asm"

%include "lib/math/expressions/parse/stack_math_ops.asm"

%include "lib/io/strcmp.asm"

%include "lib/io/strlen.asm"

%include "lib/mem/strsplit.asm"

evaluate_postfix_string:
; double {xmm0}, bool {rax} evaluate_postfix_string(char* {rdi});
; Evaluates the null-terminated postfix expression string beginning at {rdi}.
; Result of calculation in {xmm0} if null {rax}. Otherwise, {rax}=1 on fail.

	push rdi
	push rsi
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
	cmp byte [rdi],94 ; "^"
	jne .not_power
	call stack_math_ops.power
	add rsp,8
	inc rdi
	jmp .skip
.not_power:

	; check against table of operators
	mov cl,[stack_math_ops.operator_count]
	mov rsi,stack_math_ops.operator_table
.string_operator_loop:
	xor rax,rax
	mov [.operator_slot],rax
	push rdi
	push rsi
	push rdx
	mov rsi,rdi
	mov rdi,.operator_slot
	mov dl,32
	call strsplit
	pop rdx
	pop rsi
	call strcmp
	pop rdi
	cmp rax,1
	jne .not_this_string
	call [rsi+8]
	push rdi
	mov rdi,.operator_slot
	call strlen
	pop rdi
	add rdi,rax
.not_this_string:
	add rsi,16
	dec cl
	jnz .string_operator_loop

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
	pop rsi
	pop rdi

	ret

.operator_slot:
	dq 0

%endif	
