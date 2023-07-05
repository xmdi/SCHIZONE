%ifndef PRINT_ASCII
%define PRINT_ASCII

print_ascii:
; void print_ascii(int {rdi}, char {sil});
; 	Writes (non-buffered) the single byte in {sil} to file descriptor {rdi}.

	; save clobbered registers
	SYS_PUSH_SYSCALL_CLOBBERED_REGISTERS
	push rsi
	push rdx
	
	mov byte [.character],sil
	mov rsi,.character
	mov dl,1
	mov al,SYS_WRITE
	syscall

	; restore clobbered registers
	pop rdx
	pop rsi
	SYS_POP_SYSCALL_CLOBBERED_REGISTERS

	ret

.character: ; memory slot for byte to print
	db 0

%endif
