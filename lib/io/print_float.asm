%ifndef PRINT_FLOAT
%define PRINT_FLOAT

; dependencies
%include "lib/io/print_chars.asm"
%include "lib/math/expressions/log/log_10.asm"

print_float:
; void print_float(int {rdi}, double {xmm0}, int {rsi});
; 	Prints {rsi} significant digits of {xmm0} to file descriptor {rdi}.

	sub rsp,96
	movdqu [rsp+80],xmm0
	movdqu [rsp+64],xmm1
	movdqu [rsp+48],xmm2
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
;	roundsd xmm0,xmm0,0b10	; round to equal or smaller integer
	roundsd xmm0,xmm0,0b01	; round to equal or smaller integer
	cvtsd2si rdx,xmm0

	movsd xmm0,xmm8		; restore {xmm0}
	psllq xmm0,1
	psrlq xmm0,1		; abs({xmm0})

	mov rax,10
	cvtsi2sd xmm3,rax	; radix for decimal in {xmm3}

	mov rax,rdx
	inc rax		; {rax}=exponent+1 (digits to left of the decimal)

	cmp rax,rsi
	jge .huge_number 	; more digits to left of decimal than sig figs,
				; so we need to pad extra zeros to the right

	cmp rax,0		; number entirely to right of decimal
	jle .small_number	; so we need to prepend 0. ...


.medium_number:	; otherwise, our float sig figs will surround the decimal
		; (aka, UVW.XYZ)
	mov r8,rsi
	sub r8,rax	; {r8}=digits to right of the decimal
.medium_number_shift_loop:
	mulsd xmm0,xmm3		; {xmm0}*=10.0f until out of decimals
	dec r8
	jnz .medium_number_shift_loop
.medium_number_shifted:
	mov r8,rsi
	sub r8,rax	; {r8}=digits to right of the decimal
	mov rbp,rsp
	cvtsd2si rax,xmm0	; round to nearest integer!
	mov rcx,10		; integer radix for decimal in {rcx}
.medium_number_print_loop:
	xor rdx,rdx
	div rcx
	add dl,48
	dec r8
	dec rsp
	mov [rsp],dl
	test r8,r8
	jnz .medium_number_not_decimal_point
	dec rsp
	mov byte [rsp],46
.medium_number_not_decimal_point:
	test rax,rax
	jnz .medium_number_print_loop
	pxor xmm0,xmm0
	comisd xmm0,xmm8		; TODO! CAN WE DO THIS ON ITSELF?
	jc .write
	dec rsp
	mov byte [rsp],45
	jmp .write

.small_number:
	mov r8,rax	; {r8}=zeros between decimal and number
	neg r8
.small_number_shift_loop:
	mulsd xmm0,xmm3		; {xmm0}*=10.0f until out of decimals
	dec rsi
	jnz .small_number_shift_loop
.small_number_shifted:
	mov rbp,rsp
	cvtsd2si rax,xmm0	; round to nearest integer!
	mov rcx,10		; integer radix for decimal in {rcx}
.small_number_print_loop:
	xor rdx,rdx
	div rcx
	add dl,48
	dec rsp
	mov [rsp],dl
	test rax,rax
	jnz .small_number_print_loop
	test r8,r8
	jz .small_number_no_zeros
.small_number_zeros_loop:
	dec rsp
	mov byte [rsp],48	; push "0"
	dec r8	
	jnz .small_number_zeros_loop
.small_number_no_zeros:	
	dec rsp
	mov byte [rsp],46	; push "."
	dec rsp
	mov byte [rsp],48	; push "0"
	pxor xmm0,xmm0
	comisd xmm0,xmm8		; TODO! CAN WE DO THIS ON ITSELF?
	jc .write
	dec rsp
	mov byte [rsp],45
	jmp .write

.huge_number:
	mov r8,rax
	sub r8,rsi		; {r8} contains zeros after our number
	mov rbp,rsp
	cvtsd2si rax,xmm0	; round to nearest integer!
	mov rcx,10		; integer radix for decimal in {rcx}
	test r8,r8
	jz .huge_number_print_loop
.huge_number_zeros_loop:
	xor rdx,rdx
	div rcx
	dec rsp
	mov byte [rsp],48	; push "0"
	dec r8
	jnz .huge_number_zeros_loop
.huge_number_print_loop:
	xor rdx,rdx
	div rcx
	add dl,48
	dec rsp
	mov [rsp],dl
	test rax,rax
	jnz .huge_number_print_loop
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

	movdqu xmm0,[rsp+80]
	movdqu xmm1,[rsp+64]
	movdqu xmm2,[rsp+48]
	mov r8,[rsp+40]
	mov rbp,[rsp+32]
	mov rsi,[rsp+24]
	mov rdx,[rsp+16]
	mov rcx,[rsp+8]
	mov rax,[rsp+0]
	add rsp,96

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
