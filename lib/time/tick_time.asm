%ifndef TICK_TIME
%define TICK_TIME

tick_time:
; uint {rax} tick_time(void);
; 	Returns timestamp (microseconds) in {rax} and saves it at 
;	[tick_time.tick].

	SYS_PUSH_SYSCALL_CLOBBERED_REGISTERS
	push rdi
	push rsi

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

	pop rsi
	pop rdi
	SYS_POP_SYSCALL_CLOBBERED_REGISTERS

	ret

.tick:
	dq 0	; seconds
	dq 0	; microseconds

%endif
