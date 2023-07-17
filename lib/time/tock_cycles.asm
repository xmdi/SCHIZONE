%ifndef TOCK_CYCLES
%define TOCK_CYCLES

; dependency
%include "lib/time/tick_cycles.asm"

tock_cycles:
; uint {rax} tock_cycles(void);
; 	Returns difference between current and saved timestamp counter value
;	at [tick_cycles.tick] in {rax}.

	push rdx

	lfence		; force all instructions to finish
	rdtsc		; read timestamp counter into {edx}:{eax}
	shl rdx,32
	or rax,rdx	; slide {edx} into high part of {rax}
	
	sub rax,[tick_cycles.tick]	; subtract off saved value

	pop rdx

	ret

%endif
