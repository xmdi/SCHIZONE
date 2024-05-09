%ifndef STACK_MATH_OPS
%define STACK_MATH_OPS

stack_math_ops:
; void stack_math_ops(void);
; Contains a definition for many operations consisting of 1-2 operands.
; These sub-labels can be accessed directly for expression evaluation.
; Always intentionally clobbers {xmm0}. Not intended for external use.
; outside expression parsing.

db 8	; post-operation stack adjustment bytecount
.addition:
	movsd xmm0,[rsp+16]
	addsd xmm0,[rsp+8]
	movsd [rsp+16],xmm0
	ret

db 8	; post-operation stack adjustment bytecount
.subtraction:
	movsd xmm0,[rsp+16]
	subsd xmm0,[rsp+8]
	movsd [rsp+16],xmm0
	ret

db 8	; post-operation stack adjustment bytecount
.multiplication:
	movsd xmm0,[rsp+16]
	mulsd xmm0,[rsp+8]
	movsd [rsp+16],xmm0
	ret

db 8	; post-operation stack adjustment bytecount
.division:
	movsd xmm0,[rsp+16]
	divsd xmm0,[rsp+8]
	movsd [rsp+16],xmm0
	ret

db 0	; post-operation stack adjustment bytecount
.sqrt:
	sqrtsd xmm0,[rsp+8]
	movsd [rsp+8],xmm0

db 0	; post-operation stack adjustment bytecount
.exponent: ; TODO implement
	sqrtsd xmm0,[rsp+8]
	movsd [rsp+8],xmm0




%endif	
