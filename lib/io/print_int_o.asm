%ifndef PRINT_INT_O
%define PRINT_INT_O

; dependency
%include "lib/io/print_chars.asm"

print_int_o:
; void print_int_o(int {rdi}, int {rsi});
; 	Prints octal value in {rsi} to file descriptor {rdi}.

	push rax
	push rbp
	push rsi
	push rdx

	mov rbp,rsp	; save base stack pointer
	
	; value is kept in {rsi} and low bits are shifted off, three by three

	; do all arithmetic in {rax}

.loop:

	mov al,sil
	and al,7	; {al} contains low nibble of {rsi}
	add al,48	; {al} now correctly contains ascii "0"-"7"

	dec rsp
	mov [rsp],al	; move this ascii value into next slot on stack
	
	shr rsi,3	; go on to next lowest bit

	test rsi,rsi	; loop until nothing nonzero left
	jnz .loop
	
	; move leading '0o' onto stack

	dec rsp
	mov [rsp],byte 111
	
	dec rsp
	mov [rsp],byte 48
	
	; get ready to print

	mov rdx,rbp	
	sub rdx,rsp	; {rdx} will be length of number in bytes

	mov rsi,rsp	; address of top of red zone

	call print_chars	; print out bytes

	mov rsp,rbp	; restore stack pointer

	pop rdx
	pop rsi
	pop rbp
	pop rax

	ret		; return

%endif
