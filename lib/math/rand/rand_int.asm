%ifndef RAND_INT
%define RAND_INT

rand_int:
; signed long {rax} rand_int(signed long {rdi}, signed long {rsi});
; 	Returns in {rax} a random integer between {rdi} and {rsi} such that
;	{rdi}<={rax}<={rsi}.

	push rdi
	push rsi
	push rdx

	inc rsi		; increase upper bound by 1

.loop:
	rdrand rax	; random 64-bit value in {rax}
	jnc .loop	; this doesn't seem to be necessary, but we will put it
			; anyway. wait for the carry flag to be set,
			; indicating we have a valid random number in {rax}	

	xor rdx,rdx	; zero out high bits for divisionn
	sub rsi,rdi	; range of possible values in {rsi}
	div rsi		; overflow remainder in {rdx}
	add rdi,rdx	; adjust remainder to start of range

	mov rax,rdi	; final value back in {rax}

	pop rdx
	pop rsi
	pop rdi

	ret		; return

%endif
