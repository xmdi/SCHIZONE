%ifndef FILE_CLOSE
%define FILE_CLOSE

file_close:
; int {rax} file_close(int {rdi});
; 	Closes file with file descriptor {rdi}. Returns 0/-1 in {rax} on 
;	success/fail.
	
	; save clobbered registers
	SYS_PUSH_SYSCALL_CLOBBERED_REGISTERS

	mov rax,SYS_CLOSE	; set {rax} to close syscall
	syscall			; execute close syscall

	; restore clobbered registers
	SYS_POP_SYSCALL_CLOBBERED_REGISTERS

	ret			; return

%endif
