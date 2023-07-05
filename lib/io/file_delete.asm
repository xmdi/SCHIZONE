%ifndef FILE_DELETE
%define FILE_DELETE

file_delete:
; int {rax} file_delete(char* {rdi});
; 	Unlinks (deletes) file at path in char array at {rdi}. Returns 0/-1 in
;	{rax} on success/fail.
	
	; save clobbered registers
	SYS_PUSH_SYSCALL_CLOBBERED_REGISTERS

	mov rax,SYS_UNLINK	; set {rax} to unlink syscall
	syscall			; execute unlink syscall

	; restore clobbered registers
	SYS_POP_SYSCALL_CLOBBERED_REGISTERS

	ret			; return

%endif
