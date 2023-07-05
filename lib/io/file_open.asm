%ifndef FILE_OPEN
%define FILE_OPEN

file_open:
; int {rax} file_open(char* {rdi}, int {rsi}, int {rdx});
; 	Opens file in path {rdi} with {rsi} flags and permissions {rdx}
; 	Returns file descriptor in {rax} on success, -1 on fail.
	
	; save clobbered registers
	SYS_PUSH_SYSCALL_CLOBBERED_REGISTERS

	mov rax,SYS_OPEN	; set {rax} to open syscall
	syscall			; execute open syscall

	; restore clobbered registers
	SYS_POP_SYSCALL_CLOBBERED_REGISTERS

	ret			; return

%endif
