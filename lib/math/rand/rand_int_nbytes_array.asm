%ifndef RAND_INT_NBYTES_ARRAY
%define RAND_INT_NBYTES_ARRAY

rand_int_nbytes_array:
; void rand_int_nbytes_array(long* {rdi}, int {rsi}, uint {rdx}, 
;			signed long {rcx}, signed long {r8}, char {r9});
; Places {rdx} random integers in an array starting at {rdi} with 
;	({rsi}+8) bytes between elements. The random values will satisfy
;	{rcx}<={value}<={r8}. {r9} contains the number of bytes for the
; 	output integer; 1, 2, 4 & 8 valid for {r9}.

	push rdi
	push rsi
	push rdx
	push r8
	push r9
	push r10

	mov r10,rdx	; store counter in {r9}
	inc r8		; increase upper bound by 1
	sub r8,rcx	; range of possible values in {r8}

.loop:
	rdrand rax	; random 64-bit value in {rax}
	jnc .loop	; don't seem to need this, but might as well put it
			; (carry flag indicates we are done generating number)

	xor rdx,rdx	; zero out high bits for divisionn
	div r8		; overflow remainder in {rdx}
	add rdx,rcx	; adjust remainder to start of range

	cmp r9,1
	je .char
	cmp r9,2
	je .word
	cmp r9,4
	je .dword
	cmp r9,8
	je .qword

	jmp .ret

.char:
	mov byte [rdi],dl; place random integer into array
	inc rdi 	; go onto next array target
	add rdi,rsi	; extra offset between elements
	dec r10
	jnz .loop
	jmp .ret

.word:
	mov word [rdi],dx; place random integer into array
	add rdi,2	; go onto next array target
	add rdi,rsi	; extra offset between elements
	dec r10
	jnz .loop
	jmp .ret

.dword:
	mov dword [rdi],edx	; place random integer into array
	add rdi,4	; go onto next array target
	add rdi,rsi	; extra offset between elements
	dec r10
	jnz .loop
	jmp .ret

.qword:
	mov [rdi],rdx	; place random integer into array
	add rdi,8	; go onto next array target
	add rdi,rsi	; extra offset between elements
	dec r10
	jnz .loop

.ret:
	pop r10
	pop r9
	pop r8
	pop rdx
	pop rsi
	pop rdi

	ret		; return

%endif
