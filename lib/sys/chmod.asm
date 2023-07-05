%ifndef CHMOD
%define CHMOD

chmod:
; int {rax} chmod(char* {rdi}, long {rsi});
; 	Sets permissions of file with path indicated by null-terminated char 
;	array at address in {rdi} to the value in the low 9 bits of {rsi}.
;	Returns 0/-1 in {rax} on success/fail.

	; save clobbered registers
	SYS_PUSH_SYSCALL_CLOBBERED_REGISTERS

	mov rax,SYS_CHMOD	; set {rax} to chmod syscall
	syscall			; execute chmod syscall

	; restore clobbered registers
	SYS_POP_SYSCALL_CLOBBERED_REGISTERS

	ret

%endif
