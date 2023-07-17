%ifndef TICK_CYCLES
%define TICK_CYCLES

tick_cycles:
; uint {rax} tick_cycles(void);
; 	Returns timestamp counter value in {rax} and saves it at 
;	[tick_cycles.tick].

	push rdx

	lfence		; force all instructions to finish
	rdtsc		; read timestamp counter into {edx}:{eax}
	shl rdx,32
	or rax,rdx	; slide {edx} into high part of {rax}
	
	mov [tick_cycles.tick],rax

	pop rdx

	ret

.tick:
	dq 0

%endif
