%ifndef TOCK
%define TOCK

; dependency
%include "lib/time/tick.asm"

tock:
; uint {rax} tock(void);
; 	Returns difference between current and saved timestamp counter value
;	at [TICK_TIMESTAMP] in {rax}.

	push rdx

	lfence		; force all instructions to finish
	rdtsc		; read timestamp counter into {edx}:{eax}
	shl rdx,32
	or rax,rdx	; slide {edx} into high part of {rax}
	
	sub rax,[TICK_TIMESTAMP]	; subtract off saved value

	pop rdx

	ret

%endif
