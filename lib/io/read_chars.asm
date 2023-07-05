%ifndef READ_CHARS
%define READ_CHARS

read_chars:
; int {rax} read_chars(int {rdi}, char* {rsi}, int {rdx});
; Reads {rdx} chars from file descriptor {rdi} into buffer at {rsi}.
; 	Returns number of bytes read in {rax}, 0 indicates end of file,
;	and -1 indicates error.
	
	; save clobbered registers
	SYS_PUSH_SYSCALL_CLOBBERED_REGISTERS

	mov rax,SYS_READ	; set {rax} to read syscall
	syscall			; execute read syscall

	; restore clobbered registers
	SYS_POP_SYSCALL_CLOBBERED_REGISTERS

	ret			; return

%endif
