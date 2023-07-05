%ifndef PRINT_INT_D
%define PRINT_INT_D

; dependency
%include "lib/io/print_chars.asm"

print_int_d:
; void print_int_d(int {rdi}, int {rsi});
; 	Prints decimal value in {rsi} to file descriptor {rdi}.

	push rax
	push rbp
	push rsi
	push rdx
	push r8

	mov r8,rsi	; save original value in {r8}
	mov rax,rsi
	test rax,rax
	jns .positive
	neg rax
.positive:
	mov rsi,10	; divisor for decimal system
	mov rbp,rsp	; save base stack pointer
	
	; value is kept in {rax} and is divided by 10 successively

.loop:
	xor rdx,rdx	; zero out {rdx} before division
	div rsi		; divides full value in {rax} by 10
			; remainder in {rdx} ; dl = 0-9
			; result in {rax} for next time

	add dl,48	; {dl} now correctly contains ascii "0"-"9"

	dec rsp
	mov [rsp],dl	; move this ascii value into next slot on stack

	test rax,rax	; loop until nothing nonzero left
	jnz .loop
	
	test r8,r8
	jns .no_neg_sign
	dec rsp
	mov [rsp],byte 45	; add leading negative sign if necessary

.no_neg_sign:
	; get ready to print

	mov rdx,rbp	
	sub rdx,rsp	; {rdx} will be length of number in bytes

	mov rsi,rsp	; address of top of red zone

	call print_chars	; print out bytes

	mov rsp,rbp	; restore stack pointer

	pop r8
	pop rdx
	pop rsi
	pop rbp
	pop rax

	ret		; return

%endif
