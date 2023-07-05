%ifndef TOGGLE_RAW_MODE
%define TOGGLE_RAW_MODE

toggle_raw_mode:
; int {rax} toggle_raw_mode(int {rdi});
;	If {rdi}=0, toggles the terminal into raw mode (not newline 
;	buffered), saves the initial terminal configuration, and returns 
;	{rax}=1 on success. If {rdi}=1, restores the saved terminal
;	configuration and returns {rax}=0 on success.

	SYS_PUSH_SYSCALL_CLOBBERED_REGISTERS
	push rdi
	push rsi
	push rdx

	test rdi,rdi
	jz .set_raw_mode

.restore_saved_mode:

	; reset terminal to original termios
	mov rax,SYS_IOCTL
	mov rdi,SYS_STDIN
	mov rsi,SYS_TCSETA
	mov rdx,.original_termios
	syscall

	xor rax,rax	; return value 0
	jmp .done

.set_raw_mode:

	; save original termios
	mov rax,SYS_IOCTL
	mov rdi,SYS_STDIN
	mov rsi,SYS_TCGETA
	mov rdx,.original_termios
	syscall

	; save modified termios placeholder
	mov rax,SYS_IOCTL
	mov rdi,SYS_STDIN
	mov rsi,SYS_TCGETA
	mov rdx,.modified_termios
	syscall

	; adjust modified termios for raw mode;
	
	and dword [.modified_termios],~(SYS_IGNBRK+SYS_BRKINT+SYS_PARMRK+SYS_ISTRIP+SYS_INLCR+SYS_IGNCR+SYS_ICRNL+SYS_IXON)
	and dword [.modified_termios+4],~SYS_OPOST
	and dword [.modified_termios+8],~(SYS_CSIZE+SYS_PARENB)
	or dword [.modified_termios+8],SYS_CS8
	and dword [.modified_termios+12],~(SYS_ICANON+SYS_ECHO+SYS_ECHONL+SYS_ISIG+SYS_IEXTEN)

	; set terminal to modified termios for raw mode
	mov rax,SYS_IOCTL
	mov rdi,SYS_STDIN
	mov rsi,SYS_TCSETA
	mov rdx,.modified_termios
	syscall
	
	mov rax,1	; return value 1

.done:
	pop rdx
	pop rsi
	pop rdi
	SYS_POP_SYSCALL_CLOBBERED_REGISTERS

	ret

.original_termios:
	times 48 db 0

.modified_termios:
	times 48 db 0

%endif
