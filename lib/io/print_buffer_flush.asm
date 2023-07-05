%ifndef PRINT_BUFFER_FLUSH
%define PRINT_BUFFER_FLUSH

print_buffer_flush:
; void print_buffer_flush(int {rdi});
; 	Flushes the PRINT_BUFFER to file descriptor {rdi}.

	; save clobbered registers
	SYS_PUSH_SYSCALL_CLOBBERED_REGISTERS
	push rsi
	push rdx
	push rax

	mov rsi,PRINT_BUFFER	; save address of first character in {rsi}
	mov rdx,[PRINT_BUFFER_LENGTH] ; set {rdx} to number of bytes in buffer
	mov rax,SYS_WRITE	; set {rax} to write syscall
	syscall			; execute write syscall
	xor rax,rax
	mov [PRINT_BUFFER_LENGTH],rax ; reset print_buffer_length to 0

	; restore clobbered registers
	pop rax
	pop rdx
	pop rsi
	SYS_POP_SYSCALL_CLOBBERED_REGISTERS

	ret			; return

PRINT_BUFFER_LENGTH: 	; the number of bytes in the buffer
	dq 0		; initially 0, but increased by print functions

%endif
