%ifndef PRINT_INT_B
%define PRINT_INT_B

; dependency
%include "lib/io/print_chars.asm"

print_int_b:
; void print_int_b(int {rdi}, int {rsi});
; 	Prints binary value in {rsi} to file descriptor {rdi}.

	push rax
	push rbp
	push rsi
	push rdx

	mov rbp,rsp	; save base stack pointer
	
	; value is kept in {rsi} and low bits are shifted off, one by one

	; do all arithmetic in {rax}

.loop:

	mov al,sil
	and al,1
	add al,48	; {al} now contains ascii '0' or '1' corresponding
			; to lowest bit of {rsi}
	dec rsp
	mov [rsp],al	; move this ascii value into next slot on stack
	
	shr rsi,1	; go on to next lowest bit

	test rsi,rsi	; loop until nothing nonzero left
	jnz .loop
	
	; move leading '0b' onto stack

	dec rsp
	mov [rsp],byte 98
	
	dec rsp
	mov [rsp],byte 48	

	; get ready to print

	mov rdx,rbp	
	sub rdx,rsp	; {rdx} will be length of number in bytes

	mov rsi,rsp	; address of top of red zone

	call print_chars	; print out bytes

	mov rsp,rbp	; restore the stack pointer

	pop rdx
	pop rsi
	pop rbp
	pop rax

	ret		; return

%endif
