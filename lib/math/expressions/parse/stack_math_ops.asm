%ifndef STACK_MATH_OPS
%define STACK_MATH_OPS

stack_math_ops:
; void stack_math_ops(void);
; Contains a definition for many operations consisting of 1-2 operands.
; These sub-labels can be accessed directly for expression evaluation.

db 8	; post-operation stack adjustment bytecount
.addition:
	sub rsp,16
	movdqu [rsp+0],xmm0
	movsd xmm0,[rsp+32]
	addsd xmm0,[rsp+24]
	movsd [rsp+32],xmm0
	movdqu xmm0,[rsp+0]
	add rsp,16

db 8	; post-operation stack adjustment bytecount
.subtraction:
	sub rsp,16
	movdqu [rsp+0],xmm0
	movsd xmm0,[rsp+32]
	subsd xmm0,[rsp+24]
	movsd [rsp+32],xmm0
	movdqu xmm0,[rsp+0]
	add rsp,16

db 8	; post-operation stack adjustment bytecount
.multiplication:
	sub rsp,16
	movdqu [rsp+0],xmm0
	movsd xmm0,[rsp+32]
	mulsd xmm0,[rsp+24]
	movsd [rsp+32],xmm0
	movdqu xmm0,[rsp+0]
	add rsp,16

db 8	; post-operation stack adjustment bytecount
.division:
	sub rsp,16
	movdqu [rsp+0],xmm0
	movsd xmm0,[rsp+32]
	divsd xmm0,[rsp+24]
	movsd [rsp+32],xmm0
	movdqu xmm0,[rsp+0]
	add rsp,16

db 0	; post-operation stack adjustment bytecount
.sqrt:
	sub rsp,16
	movdqu [rsp+0],xmm0
	sqrtsd xmm0,[rsp+24]
	movsd [rsp+24],xmm0
	movdqu xmm0,[rsp+0]
	add rsp,16

db 0	; post-operation stack adjustment bytecount
.power: ; TODO implement
	sub rsp,16
	movdqu [rsp+0],xmm0
	sqrtsd xmm0,[rsp+24]
	movsd [rsp+24],xmm0
	movdqu xmm0,[rsp+0]
	add rsp,16




%endif	
