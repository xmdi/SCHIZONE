%ifndef PRINT_BUFFER_FLUSH_TO_MEMORY
%define PRINT_BUFFER_FLUSH_TO_MEMORY

%include "lib/mem/memcopy.asm"
%include "lib/io/print_buffer_reset.asm"

print_buffer_flush_to_memory:
; void print_buffer_flush_to_memory(void* {rdi});
; 	Flushes the PRINT_BUFFER to memory address {rdi}.

	; save clobbered registers
	push rsi
	push rdx

	mov rsi,PRINT_BUFFER	; save address of first character in {rsi}
	mov rdx,[PRINT_BUFFER_LENGTH] ; set {rdx} to number of bytes in buffer
	call memcopy		; copy print buffer to target
	
	call print_buffer_reset	; reset print buffer

	; restore clobbered registers
	pop rdx
	pop rsi

	ret			; return

%endif
