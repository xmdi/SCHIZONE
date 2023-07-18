%ifndef SLEEP
%define SLEEP

sleep:
; void sleep(uint {rdi});
; 	Sleeps for at least {rdi} microseconds.

	SYS_PUSH_SYSCALL_CLOBBERED_REGISTERS
	push rdi
	push rsi
	push rdx
	push r15

	; save delay in {r15}
	mov r15,rdi

	; syscall for current timestamp
	mov rax,SYS_GETTIMEOFDAY
	mov rdi,sleep.tick
	xor rsi,rsi
	syscall

	; get current timestamp_microseconds in {rdx}
	mov rdx,[sleep.tick]
	mov rdi,1000000
	imul rdx,rdi
	add rdx,[sleep.tick+8]

	; adjust {r15} to the targeted timestamp microsecond
	add r15,rdx

.loop:

	; syscall for current timestamp
	mov rax,SYS_GETTIMEOFDAY
	mov rdi,sleep.tick
	xor rsi,rsi
	syscall

	; get current timestamp_microseconds in {rax}
	mov rax,[sleep.tick]
	mov rdi,1000000
	imul rax,rdi
	add rax,[sleep.tick+8]

	; loop until we hit the target timestamp
	cmp rax,r15
	jl .loop

	pop r15
	pop rdx
	pop rsi
	pop rdi
	SYS_POP_SYSCALL_CLOBBERED_REGISTERS

	ret

.tick:
	dq 0	; seconds
	dq 0	; microseconds

%endif
