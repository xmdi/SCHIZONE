%ifndef TICK
%define TICK

tick:
; uint {rax} tick(void);
; 	Returns timestamp counter value in {rax} and saves it in a global
;	variable at [TICK_TIMESTAMP].

	push rdx

	lfence		; force all instructions to finish
	rdtsc		; read timestamp counter into {edx}:{eax}
	shl rdx,32
	or rax,rdx	; slide {edx} into high part of {rax}
	
	mov [TICK_TIMESTAMP],rax

	pop rdx

	ret

TICK_TIMESTAMP:
	dq 0

%endif
