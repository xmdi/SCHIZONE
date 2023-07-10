%ifndef RAND_INT_ARRAY
%define RAND_INT_ARRAY

rand_int_array:
; void rand_int_array(long* {rdi}, int {rsi}, uint {rdx}, 
;			signed long {rcx}, signed long {r8});
; Places {rdx} random integers in an array starting at {rdi} with 
;	({rsi}+8) bytes between elements. The random values will satisfy
;	{rcx}<={value}<={r8}.

	push rdi
	push rsi
	push rdx
	push r8
	push r9

	mov r9,rdx	; store counter in {r9}
	inc r8		; increase upper bound by 1
	sub r8,rcx	; range of possible values in {r8}

.loop:
	rdrand rax	; random 64-bit value in {rax}
	jnc .loop	; don't seem to need this, but might as well put it
			; (carry flag indicates we are done generating number)

	xor rdx,rdx	; zero out high bits for divisionn
	div r8		; overflow remainder in {rdx}
	add rdx,rcx	; adjust remainder to start of range

	mov [rdi],rdx	; place random integer into array
	add rdi,8	; go onto next array target
	add rdi,rsi	; extra offset between elements
	
	dec r9
	jnz .loop

	pop r9
	pop r8
	pop rdx
	pop rsi
	pop rdi

	ret		; return

%endif
