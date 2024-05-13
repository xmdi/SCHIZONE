%ifndef POW
%define POW

%include "lib/math/expressions/log/exp.asm"
%include "lib/math/expressions/log/log_e.asm"

align 16

pow:
; double {xmm0} pow(double {xmm0}, double {xmm1}, double {xmm2});
;	Computes approximation of {xmm0}^{xmm1} to
;	within guidance {xmm2}, via Taylor series expansions
;	returning in {xmm0}.

;	NOTE: passing in a negative base will result in NaN return
;		because imaginary numbers are fake imo.

	; example: 3.4^7.2 
		
	; integer exponent part: 3.4^7
	;	compute via loop

	; fraction exponent part: 3.4^.2
	;	compute as exp(.2*log_e(3.4))

	; multiply the two together

	; ret

	push rcx
	push r8	
	sub rsp,48
	movdqu [rsp+0],xmm1
	movdqu [rsp+16],xmm3
	movdqu [rsp+32],xmm4

	xor r8,r8
	pxor xmm3,xmm3
	comisd xmm0,xmm3
	jb .ret_NaN
	comisd xmm1,xmm3
	jae .positive_input
	inc r8
	pslld xmm1,1
	psrld xmm1,1
.positive_input:
	movsd xmm4,[.one]	
	comisd xmm1,xmm4
	jb .fraction_exponent_prep

	cvtsd2si rcx,xmm1

.integer_exponent_loop:
	mulsd xmm4,xmm0	
	subsd xmm1,[.one]
	dec rcx
	jnz .integer_exponent_loop

.fraction_exponent_prep:

	movsd xmm3,xmm1 ; fractional part of exponent
	
	movsd xmm1,xmm2
	call log_e	; {xmm0} contains ln(base)
	mulsd xmm0,xmm3	 
	call exp	; {xmm0} contains the full fractional power

	mulsd xmm0,xmm4

	cmp r8,1
	jne .leave
	; was negative exponent
	movsd xmm3,[.one]
	divsd xmm3,xmm0
	movsd xmm0,xmm3
.leave:

	movdqu xmm1,[rsp+0]
	movdqu xmm3,[rsp+16]
	movdqu xmm4,[rsp+32]
	add rsp,48
	pop r8
	pop rcx

	ret

.ret_NaN:
	movsd xmm0,[.NaN]
	jmp .leave	

align 8

.one:
	dq 1.0
.NaN:
	dq 0x7FF0000000000001 

%endif
