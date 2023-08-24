%ifndef PARSE_FLOAT
%define PARSE_FLOAT

parse_float:
; double {xmm0} parse_float(char* {rdi});
; 	Returns in {xmm0} the value of char array starting at 
;	{rdi} and terminating with any non-numerical character 
;	besides `.`.

	push rdi
	push rsi
	push rax
	push rbx
	push rcx
	push rdx		; "imul r64"  messes up {rdx} btw
	push r8
	sub rsp,32
	movdqu xmm1,[rsp+16]
	movdqu xmm2,[rsp+0]

	xor r8,r8		; flag for negative number
	mov rcx,10		; radix for decimal system
	cmp byte [rdi],45
	jne .loop_integer
	inc rdi
	inc r8
	
.loop_integer:

	movzx rbx, byte [rdi]	; grab current byte
	sub rbx,48
	imul rcx
	add rax,rbx

	inc rdi
	cmp byte [rdi],101	; parse scientific notation on "e"
	je .parse_scientific_integer
	cmp byte [rdi],57	; break if the next byte is non numeric
	jg .done_no_fraction
	cmp byte [rdi],46
	jl .done_no_fraction
	cmp byte [rdi],47
	je .done_no_fraction
	cmp byte [rdi],46	; go to fraction parsing part on decimal point
	jne .loop_integer

	cvtsi2sd xmm1,rax	; save integer part in {xmm1}
	inc rdi
	xor rax,rax
	mov rsi,1		; multiplier for fractional denominator

.loop_fraction:
	movzx rbx, byte [rdi]	; grab current byte
	sub rbx,48
	imul rcx
	imul rsi,rcx
	add rax,rbx

	inc rdi	
	cmp byte [rdi],101	; go to exponent parsing part on "e"
	je .parse_exponent
	cmp byte [rdi],57	; break if the next byte is non numeric
	jg .done_fraction
	cmp byte [rdi],48
	jl .done_fraction
	jmp .loop_fraction

.parse_exponent:
	cvtsi2sd xmm0,rax
	cvtsi2sd xmm2,rsi
	divsd xmm0,xmm2
	addsd xmm0,xmm1
	test r8,r8
	jz .parse_exponent_go
	mov rax,-1
	cvtsi2sd xmm1,rax
	mulsd xmm0,xmm1
.parse_exponent_go:

	inc rdi
	xor rax,rax
	xor r8,r8
	cmp byte [rdi],45 	; check for negative exponent
	jne .loop_exponent
	inc rdi
	inc r8

.loop_exponent:
	movzx rbx, byte [rdi]	; grab current byte
	sub rbx,48
	imul rcx
	add rax,rbx

	inc rdi	
	cmp byte [rdi],57	; break if the next byte is non numeric
	jg .done_exponent
	cmp byte [rdi],48
	jl .done_exponent
	jmp .loop_exponent

.done_exponent:
	mov rsi,rax
	mov rax,1

.loop_exponent_power:
	imul rcx
	dec rsi
	jnz .loop_exponent_power
	cvtsi2sd xmm1,rax

	test r8,r8
	jz .positive_exponent
	divsd xmm0,xmm1
	jmp .done
.positive_exponent:
	mulsd xmm0,xmm1
	jmp .done

.done_fraction:
	cvtsi2sd xmm0,rax
	cvtsi2sd xmm2,rsi
	divsd xmm0,xmm2
	addsd xmm0,xmm1
	test r8,r8
	jz .done
	mov rcx,-1
	cvtsi2sd xmm1,rcx
	mulsd xmm0,xmm1
	jmp .done

.done_no_fraction:
	test r8,r8
	jz .done_no_negate_no_fraction
	mov rcx,-1
	imul rcx
.done_no_negate_no_fraction:
	cvtsi2sd xmm0,rax

.done:
	movdqu xmm2,[rsp+0]
	movdqu xmm1,[rsp+16]
	add rsp,32
	pop r8
	pop rdx
	pop rcx
	pop rbx
	pop rax	
	pop rsi
	pop rdi
	ret

.parse_scientific_integer:
	test r8,r8
	jz .no_negate_scientific_integer
	mov rsi,-1
	imul rsi
.no_negate_scientific_integer:
	cvtsi2sd xmm0,rax
	jmp .parse_exponent_go

%endif
