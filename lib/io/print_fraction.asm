%ifndef PRINT_FRACTION
%define PRINT_FRACTION

; dependency
%include "lib/io/print_chars.asm"
%include "lib/io/print_int_d.asm"

print_fraction:
; void print_fraction(int {rdi}, int {rsi}, int {rdx});
; 	Prints "{rsi}/{rdx}" to file descriptor {rdi}.

	push rsi
	push rdx

	; print numerator
	call print_int_d

	; print "/"
	mov rsi,.grammar
	mov rdx,1
	call print_chars

	; print denominator
	mov rsi,[rsp+0]
	call print_int_d

	pop rdx
	pop rsi

	ret		; return

.grammar:
	db `/`

%endif
