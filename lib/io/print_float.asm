%ifndef PRINT_FLOAT
%define PRINT_FLOAT

; dependencies
%include "lib/io/print_chars.asm"
%include "lib/math/expressions/log/log_10.asm"

print_float:
; void print_float(int {rdi}, double {xmm0}, int {rsi});
; 	Prints {rsi} significant digits of {xmm0} to file descriptor {rdi}.


	movq rax,xmm0

	; check special cases
	test rax,rax
	jz .ret_pos_zero
	cmp rax,[.neg_zero]
	je .ret_neg_zero
	cmp rax,[.pos_inf]
	je .ret_pos_inf
	cmp rax,[.neg_inf]
	je .ret_neg_inf
	and rax,[.NaN_mask]
	cmp rax,[.NaN_mask]
	je .ret_NaN

	movsd xmm0,xmm8		; save initial value in {xmm8}
	pslld xmm0,1
	psrld xmm0,1		; abs({xmm0})

	; compute the exponent (power of 10) in {rdx}
	movsd xmm1,[.tolerance]
	call log_10
	roundsd xmm0,xmm0,0b01	; round to equal or smaller integer
	cvtsd2si rdx,xmm0

	mov rax,10
	cvtsi2sd xmm3,rax	; radix for decimal in {xmm3}

	test rdx,rdx
	js .small_number	; negative exponent means abs(float)<1
				; so float will begin with "0."

	mov rax,rdx
	inc rax		; {rax}=exponent+1 (digits to left of the decimal)

	cmp rax,rsi
	jge .huge_number 	; more digits to left of decimal than sig figs,
				; so we need to pad extra zeros to the right

.medium_number:	; otherwise, our float sig figs will surround the decimal
		; (aka, UVW.XYZ)
	mov r8,rsi
	sub r8,rax	; {r8}=digits to right of the decimal
.medium_number_shift_loop:
	mulsd xmm0,xmm3		; {xmm0}*=10.0f until out of decimals
	dec r8
	jnz .medium_number_shift_loop
.medium_number_shifted:
	mov rbp,rsp
	cvtsd2si rax,xmm0	; round to nearest integer!
	mov rcx,10		; integer radix for decimal in {rcx}
.medium_number_print_loop:
	xor rdx,rdx
	div rcx
	add dl,48
	dec rsi
	dec rbp
	mov [rbp],dl
	cmp rax,rsi
	jne .medium_number_not_decimal_point
	dec rsi
	mov byte [rbp],46
.medium_number_not_decimal_point:
	test rax,rax
	jnz .medium_number_print_loop
	pxor xmm0,xmm0
	comisd xmm0,xmm8		; TODO! CAN WE DO THIS ON ITSELF?
	jc .write
	dec rbp
	mov byte [rbp],45
	jmp .write










.write:
	mov rdx,rsp
	sub rdx,rbp
	mov rsi,rbp
	call print_chars

.ret_pos_zero:
	mov rbp,rsp
	sub rbp,4
	mov byte [rbp+3],48	; push 0 character
	mov byte [rbp+2],46	; push . character
	mov byte [rbp+1],48	; push 0 character
	mov byte [rbp+0],43	; push + character
	jmp .write
.ret_neg_zero:
	mov rbp,rsp
	sub rbp,4
	mov byte [rbp+3],48	; push 0 character
	mov byte [rbp+2],46	; push . character
	mov byte [rbp+1],48	; push 0 character
	mov byte [rbp+0],45	; push - character
	jmp .write
.ret_pos_inf:
	mov rbp,rsp
	sub rbp,4
	mov byte [rbp+3],102	; push f character
	mov byte [rbp+2],110	; push n character
	mov byte [rbp+1],73	; push I character
	mov byte [rbp+0],43	; push + character
	jmp .write
.ret_neg_inf:
	mov rbp,rsp
	sub rbp,4
	mov byte [rbp+3],102	; push f character
	mov byte [rbp+2],110	; push n character
	mov byte [rbp+1],73	; push I character
	mov byte [rbp+0],45	; push - character
	jmp .write
.ret_NaN:
	mov rbp,rsp
	sub rbp,3
	mov byte [rbp+2],78	; push N character
	mov byte [rbp+1],97	; push a character
	mov byte [rbp+0],78	; push N character
	jmp .write

align 8
.neg_zero:
	dq 0x8000000000000000 ; -0.0
.pos_inf:
	dq 0x7FF0000000000000 ; +Inf
.neg_inf:
	dq 0xFFF0000000000000 ; -Inf
.NaN_mask:
	dq 0x7FF0000000000000 ; NaN
.tolerance:
	dq 0.000000001 ; we honestly don't need a tolerance this low, but YOLO

%endif
