%ifndef FRAMERATE_POLL
%define FRAMERATE_POLL

framerate_poll:
; void framerate_poll(void);
;	This function can be called every frame to populate a double at
;	[framerate_poll.framerate] containing the average framerate
;	(frames/second) over the past 30 frames.

	SYS_PUSH_SYSCALL_CLOBBERED_REGISTERS
	push rdi
	push rsi
	push rdx
	push rax
	sub rsp,32
	movdqu [rsp+0],xmm0
	movdqu [rsp+16],xmm1

	; check if 30 frames have elapsed
	cmp byte [.framecount],30
	jbe .no_calc
	
	; query ending timestamp
	mov rax,SYS_GETTIMEOFDAY
	mov rdi,.timestamp_end
	xor rsi,rsi
	syscall

	; convert start timestamp to microseconds
	mov rdx,[.timestamp_start]
	mov rdi,1000000
	imul rdx,rdi
	add rdx,[.timestamp_start+8]
	
	; convert end timestamp to microseconds
	mov rax,[.timestamp_end]
	imul rax,rdi
	add rax,[.timestamp_end+8]
	
	; compute framerate
	sub rax,rdx
	cvtsi2sd xmm1,rax
	movsd xmm0,[.conversion]
	divsd xmm0,xmm1
	movsd [.framerate],xmm0

	; reset starting timestamp values
	mov rax,[.timestamp_end]
	mov [.timestamp_start],rax
	mov rax,[.timestamp_end+8]
	mov [.timestamp_start+8],rax

	; reset framecount
	xor rsi,rsi
	mov [.framecount],sil

.no_calc:
	; increment framecount
	inc byte [.framecount]	

	movdqu xmm0,[rsp+0]
	movdqu xmm1,[rsp+16]
	add rsp,32
	pop rax
	pop rdx
	pop rsi
	pop rdi
	SYS_POP_SYSCALL_CLOBBERED_REGISTERS

	ret

.framerate:
	dq __Infinity__

.timestamp_start:
	times 2 dq 0
	
.timestamp_end:
	times 2 dq 0

.conversion: ; 1e6*30
	dq 30000000.0

.framecount:
	db 200

%endif
