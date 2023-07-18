%ifndef TOCK_TIME
%define TOCK_TIME

; dependency
%include "lib/time/tick_time.asm"

tock_time:
; uint {rax} tock_time(void);
; 	Returns microseconds that have elapsed since last call of
;	tick_time in {rax}.

	SYS_PUSH_SYSCALL_CLOBBERED_REGISTERS
	push rdi
	push rsi
	push rdx

	; save previous timestamp microseconds in {rdx}
	mov rdx,[tick_time.tick]
	mov rdi,1000000
	imul rdx,rdi
	add rdx,[tick_time.tick+8]

	; syscall for current timestamp
	mov rax,SYS_GETTIMEOFDAY
	mov rdi,tick_time.tick
	xor rsi,rsi
	syscall

	; get current timestamp_microseconds in {rax}
	mov rax,[tick_time.tick]
	mov rdi,1000000
	imul rax,rdi
	add rax,[tick_time.tick+8]

	; compute the elapsed microseconds
	sub rax,rdx

	pop rdx
	pop rsi
	pop rdi
	SYS_POP_SYSCALL_CLOBBERED_REGISTERS

	ret

%endif
