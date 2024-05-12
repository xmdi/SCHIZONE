%ifndef STACK_MATH_OPS
%define STACK_MATH_OPS

%include "lib/math/expressions/trig/sine.asm"
%include "lib/math/expressions/trig/cosine.asm"
%include "lib/math/expressions/trig/tangent.asm"
%include "lib/math/expressions/trig/arctangent.asm"
%include "lib/math/expressions/log/log_e.asm"
%include "lib/math/expressions/log/log_10.asm"

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
	ret

db 0	; post-operation stack adjustment bytecount
.power: ; TODO implement
	sqrtsd xmm0,[rsp+8]
	movsd [rsp+8],xmm0

db 0	; post-operation stack adjustment bytecount
.exp: ; TODO implement
	sqrtsd xmm0,[rsp+8]
	movsd [rsp+8],xmm0

db 0	; post-operation stack adjustment bytecount
.sine: 
	sub rsp,16
	movdqu [rsp+0],xmm1
	movsd xmm0,[rsp+24]
	movsd xmm1,[.tolerance]	
	call sine
	movsd [rsp+24],xmm0
	movdqu xmm1,[rsp+0]
	add rsp,16
	ret

db 0	; post-operation stack adjustment bytecount
.cosine: 
	sub rsp,16
	movdqu [rsp+0],xmm1
	movsd xmm0,[rsp+24]
	movsd xmm1,[.tolerance]	
	call cosine
	movsd [rsp+24],xmm0
	movdqu xmm1,[rsp+0]
	add rsp,16
	ret

db 0	; post-operation stack adjustment bytecount
.tangent: 
	sub rsp,16
	movdqu [rsp+0],xmm1
	movsd xmm0,[rsp+24]
	movsd xmm1,[.tolerance]	
	call tangent
	movsd [rsp+24],xmm0
	movdqu xmm1,[rsp+0]
	add rsp,16
	ret

db 8	; post-operation stack adjustment bytecount
.arctangent: 
	sub rsp,32
	movdqu [rsp+0],xmm1
	movdqu [rsp+16],xmm1
	movsd xmm0,[rsp+48]
	movsd xmm1,[rsp+40]
	movsd xmm2,[.tolerance]	
	call arctangent
	movsd [rsp+48],xmm0
	movdqu xmm1,[rsp+0]
	movdqu xmm2,[rsp+16]
	add rsp,32
	ret

db 0	; post-operation stack adjustment bytecount
.inv:
	movsd xmm0,[.one]
	divsd xmm0,[rsp+8]
	movsd [rsp+8],xmm0
	ret

db 0	; post-operation stack adjustment bytecount
.ln: 
	sub rsp,16
	movdqu [rsp+0],xmm1
	movsd xmm0,[rsp+24]
	movsd xmm1,[.tolerance]	
	call log_e
	movsd [rsp+24],xmm0
	movdqu xmm1,[rsp+0]
	add rsp,16
	ret

db 0	; post-operation stack adjustment bytecount
.log: 
	sub rsp,16
	movdqu [rsp+0],xmm1
	movsd xmm0,[rsp+24]
	movsd xmm1,[.tolerance]	
	call log_10
	movsd [rsp+24],xmm0
	movdqu xmm1,[rsp+0]
	add rsp,16
	ret

db 0	; post-operation stack adjustment bytecount
.pi:
	sub rsp,8
	push rax
	mov rax,[rsp+16]
	mov [rsp+8],rax
	movsd xmm0,[.const_pi]
	movsd [rsp+16],xmm0
	pop rax
	ret

db 0	; post-operation stack adjustment bytecount
.tau:
	sub rsp,8
	push rax
	mov rax,[rsp+16]
	mov [rsp+8],rax
	movsd xmm0,[.const_tau]
	movsd [rsp+16],xmm0
	pop rax
	ret

db 0	; post-operation stack adjustment bytecount
.e:
	sub rsp,8
	push rax
	mov rax,[rsp+16]
	mov [rsp+8],rax
	movsd xmm0,[.const_e]
	movsd [rsp+16],xmm0
	pop rax
	ret

.one:
	dq 1.0
.const_pi:
	dq 0x400921fb54442d18
.const_tau:
	dq 0x401921fb54442d18
.const_e:
	dq 0x4005bf0a8b145769
.tolerance:
	dq 0.0000001

%endif	
