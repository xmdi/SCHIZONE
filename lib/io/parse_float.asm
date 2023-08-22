%ifndef PARSE_FLOAT
%define PARSE_FLOAT

parse_float:
; double {xmm0} parse_float(char* {rdi});
; 	Returns in {xmm0} the value of char array starting at 
;	{rdi} and terminating with any non-numerical character 
;	besides `.`.

	xor r8,r8		; flag for negative number
	mov rcx,10		; radix for decimal system
	mov rdx,1
	movzx rbx, byte [rdi]
	cmp rbx,45
	jne .loop
	inc rdi
	inc r8	
.loop:
	movzx rbx, byte [rdi]	; grab current byte
	sub rbx,48
	imul rcx
	add rax,rbx

	inc rdi
	cmp byte [rdi],57	; break if the next byte is non numeric
	jg .done
	cmp byte [rdi],46
	jl .done
	cmp byte [rdi],47
	jne .loop
	; save integer part, move onto fraction part
	cvtsi2sd xmm1,rax


.done:
	cvtsi2sd xmm0,rax

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
