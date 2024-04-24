%ifndef PRINT_BUFFER_RESET
%define PRINT_BUFFER_RESET

print_buffer_reset:
; void print_buffer_reset(void);
; 	Clears the PRINT_BUFFER.

	push rax

	xor rax,rax
	mov [PRINT_BUFFER_LENGTH],rax ; reset print_buffer_length to 0

	pop rax

	ret			; return

%endif
