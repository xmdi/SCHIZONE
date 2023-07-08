%ifndef RAND_INT_ARRAY
%define RAND_INT_ARRAY

rand_int_array:
; void rand_int_array(long* {rdi}, int {rsi}, uint {rdx}, 
;			signed long {rcx}, signed long {r8});
; 	Places {rdx} random integers in an array starting at {rdi} with 
;	({rsi}+8) bytes between elements. The random values will satisfy
;	{rcx}<={value}<={r8}.

	push rdi
	push rsi
	push rdx

	inc rsi		; increase upper bound by 1

	rdrand rax	; random 64-bit value in {rax}

	xor rdx,rdx	; zero out high bits for divisionn
	sub rsi,rdi	; range of possible values in {rsi}
	div rsi		; overflow remainder in {rsi}
	add rdi,rdx	; adjust remainder to start of range

	mov rax,rdi	; final value back in {rax}

	pop rdx
	pop rsi
	pop rdi

	ret		; return

%endif
