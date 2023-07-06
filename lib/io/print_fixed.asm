%ifndef PRINT_FIXED
%define PRINT_FIXED

; dependency
%include "lib/io/print_chars.asm"
%include "lib/io/print_int_d.asm"

print_fixed:
; void print_fixed(int {rdi}, int {rsi}, int {rdx});
; 	Prints fixed-point value in {rsi} to file descriptor {rdi}
;	with the low {rdx} bits representing the fraction.

	push rsi
	push rdx
	push rcx

	test rsi,rsi
	jns .positive

	; print "-("
	mov rsi,.grammar+2
	mov rdx,2
	call print_chars

	mov rsi,[rsp+16]
	neg rsi

.positive:	
	; print integer part
	mov rcx,[rsp+8]
	sar rsi,cl
	call print_int_d

	; print "+"
	mov rsi,.grammar
	mov rdx,1
	call print_chars

	; print numerator
	mov rsi,[rsp+16]
	mov rdx,-1
	shl rdx,cl
	not rdx			; {rdx} mask off integer part
	and rsi,rdx
	call print_int_d

	; print "/"	
	mov rsi,.grammar+1
	mov rdx,1
	call print_chars

	; print denominator
	mov rsi,1
	mov rcx,[rsp+8]
	shl rsi,cl
	call print_int_d	

	mov rsi,[rsp+16]
	test rsi,rsi
	jns .done

	; print ")"
	mov rsi,.grammar+4
	mov rdx,1
	call print_chars

.done:
	pop rcx
	pop rdx
	pop rsi

	ret

.grammar:
	db `+/-()`

%endif
