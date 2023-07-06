%ifndef PRINT_FLOAT_SCIENTIFIC
%define PRINT_FLOAT_SCIENTIFIC

; dependencies
%include "lib/io/print_chars.asm"
%include "lib/math/expressions/log/log_10.asm"

print_float_scientific:
; void print_float_scientific(int {rdi}, double {xmm0}, int {rsi});
; 	Prints {rsi} significant digits of {xmm0} to file descriptor {rdi}
;	in scientific notation.

	sub rsp,112
	movdqu [rsp+96],xmm0
	movdqu [rsp+80],xmm1
	movdqu [rsp+64],xmm3
	movdqu [rsp+48],xmm8
	mov [rsp+40],r8
	mov [rsp+32],rbp
	mov [rsp+24],rsi
	mov [rsp+16],rdx
	mov [rsp+8],rcx
	mov [rsp+0],rax

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

	movsd xmm8,xmm0		; save initial value in {xmm8}
	psllq xmm0,1
	psrlq xmm0,1		; abs({xmm0})

	; compute the exponent (power of 10) in {rdx}
	movsd xmm1,[.tolerance]
	call log_10
	roundsd xmm0,xmm0,0b01	; round to equal or smaller integer
	cvtsd2si rdx,xmm0

	movsd xmm0,xmm8		; restore {xmm0}
	psllq xmm0,1
	psrlq xmm0,1		; abs({xmm0})

;	print exponent
	mov rbp,rsp
	mov rax,rdx
	test rax,rax
	jns .positive_exponent	; {rax} positive exponent
	neg rax
.positive_exponent:		
	mov r8,rdx		; save original exponent in {r8}
	mov rcx,10		; integer radix for decimal in {rcx}
.exponent_loop:
	xor rdx,rdx
	div rcx
	add dl,48
	dec rsp
	mov [rsp],dl
	test rax,rax
	jnz .exponent_loop
	test r8,r8
	jns .no_negative_sign_in_exponent
	dec rsp
	mov byte [rsp],45
.no_negative_sign_in_exponent:

	dec rsp
	mov byte [rsp],101	; "e" for exponent

;	shift the number {rsi}-1-exp digits (base-10) to the left
	cvtsi2sd xmm3,rcx
	neg r8
	dec r8
	add r8,rsi		; {r8} now counts the leftward shift amount
	cmp r8,0
	jg .shift_up_loop
	je .done_shifting
.shift_down_loop:
	divsd xmm0,xmm3		; {xmm0}/=10.0f until out of decimals
	inc r8
	jnz .shift_down_loop
	jmp .done_shifting
.shift_up_loop:
	mulsd xmm0,xmm3		; {xmm0}*=10.0f until out of decimals
	dec r8
	jnz .shift_up_loop
.done_shifting:
;	print {rsi}-1 digits of the number
	dec rsi	
	cvtsd2si rax,xmm0	; round to nearest integer!
	mov rcx,10		; integer radix for decimal in {rcx}
	test rsi,rsi
	jz .decimal_point
.number_print_loop:
	xor rdx,rdx
	div rcx
	add dl,48
	dec rsp
	mov [rsp],dl
	dec rsi
	jnz .number_print_loop	
.decimal_point:
	dec rsp
	mov byte [rsp],46	; decimal point
.last_digits: ; this loop may execute twice for certain powers of 10
	xor rdx,rdx
	div rcx
	add dl,48
	dec rsp
	mov [rsp],dl
	test rax,rax
	jnz .last_digits
	pxor xmm0,xmm0
	comisd xmm0,xmm8		; TODO! CAN WE DO THIS ON ITSELF?
	jc .write
	dec rsp
	mov byte [rsp],45

.write:
	mov rdx,rbp
	sub rdx,rsp
	mov rsi,rsp
	call print_chars

	mov rsp,rbp

	movdqu xmm0,[rsp+96]
	movdqu xmm1,[rsp+80]
	movdqu xmm3,[rsp+64]
	movdqu xmm8,[rsp+48]
	mov r8,[rsp+40]
	mov rbp,[rsp+32]
	mov rsi,[rsp+24]
	mov rdx,[rsp+16]
	mov rcx,[rsp+8]
	mov rax,[rsp+0]
	add rsp,112

	ret	


.ret_pos_zero:
	mov rbp,rsp
	sub rsp,4
	mov byte [rsp+3],48	; push 0 character
	mov byte [rsp+2],46	; push . character
	mov byte [rsp+1],48	; push 0 character
	mov byte [rsp+0],43	; push + character
	jmp .write
.ret_neg_zero:
	mov rbp,rsp
	sub rsp,4
	mov byte [rsp+3],48	; push 0 character
	mov byte [rsp+2],46	; push . character
	mov byte [rsp+1],48	; push 0 character
	mov byte [rsp+0],45	; push - character
	jmp .write
.ret_pos_inf:
	mov rbp,rsp
	sub rsp,4
	mov byte [rsp+3],102	; push f character
	mov byte [rsp+2],110	; push n character
	mov byte [rsp+1],73	; push I character
	mov byte [rsp+0],43	; push + character
	jmp .write
.ret_neg_inf:
	mov rbp,rsp
	sub rsp,4
	mov byte [rsp+3],102	; push f character
	mov byte [rsp+2],110	; push n character
	mov byte [rsp+1],73	; push I character
	mov byte [rsp+0],45	; push - character
	jmp .write
.ret_NaN:
	mov rbp,rsp
	sub rsp,3
	mov byte [rsp+2],78	; push N character
	mov byte [rsp+1],97	; push a character
	mov byte [rsp+0],78	; push N character
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
