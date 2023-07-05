%ifndef PRINT_INT_H
%define PRINT_INT_H

; dependency
%include "lib/io/print_chars.asm"

print_int_h:
; void print_int_h(int {rdi}, int {rsi});
; 	Prints hexadecimal value in {rsi} to file descriptor {rdi}.

	push rax
	push rbp
	push rsi
	push rdx

	mov rbp,rsp	; save base stack pointer
	
	; value is kept in {rsi} and low bits are shifted off, four by four

	; do all arithmetic in {rax}

.loop:

	mov al,sil
	and al,15	; {al} contains low nibble of {rsi}
	add al,48	; {al} now correctly contains ascii "0"-"9"

	cmp al,57
	jle .insert_byte
	add al,39	; adjust {al} for ascii "a"-"f"
.insert_byte:
	dec rsp
	mov [rsp],al	; move this ascii value into next slot on stack
	
	shr rsi,4	; go on to next lowest bit

	test rsi,rsi	; loop until nothing nonzero left
	jnz .loop
	
	; move leading '0x' onto stack

	dec rsp
	mov [rsp],byte 120
	
	dec rsp
	mov [rsp],byte 48	

	; get ready to print

	mov rdx,rbp	
	sub rdx,rsp	; {rdx} will be length of number in bytes

	mov rsi,rsp	; address of top of stack

	call print_chars	; print out bytes

	mov rsp,rbp	; restore stack pointer

	pop rdx
	pop rsi
	pop rbp
	pop rax

	ret		; return

%endif
