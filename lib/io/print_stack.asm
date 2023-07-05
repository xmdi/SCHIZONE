%ifndef PRINT_STACK
%define PRINT_STACK

; dependency
%include "lib/io/print_chars.asm"
%include "lib/io/print_int_h.asm"
%include "lib/io/print_int_d.asm"
%include "lib/io/print_int_o.asm"
%include "lib/io/print_int_b.asm"

print_stack:
; void print_stack(int {rdi}, int {rsi}, void* {rdx});
; Prints stack contents starting at {rsi} quadwords above the stack pointer to
;	file descriptor {rdi}. {rdx} points to the function used to print
;	integers in the desired format.

	push rsi
	push rax
	push rbx
	push rcx
	push rdx
	push rbp

	mov rbp,rsi	; {rbp} tracks the offset to the current value to print
	shl rbp,3	; convert {rbp} to bytes
	mov rcx,rbp	; {rcx} contains the byte offset from the stack
	add rbp,rsp	; offset {rbp} by the stack pointer
	add rbp,48	; offset by the callee-saved registers
	mov rbx,rdx	; {rbx} contains function pointer to call

.loop:
	; print `\n[rsp+`
	mov rsi,.grammar
	mov rdx,6
	call print_chars	

	; print number
	mov rsi,rcx
	call print_int_d

	; print `]:\t`
	mov rsi,.grammar+6
	mov rdx,3
	call print_chars

	; print value
	mov rsi,[rbp]
	call rbx

	; loop until at the stack pointer
	sub rbp,8
	sub rcx,8
	jns .loop

	; print last newline
	mov rsi,.grammar
	mov rdx,1
	call print_chars

	pop rbp
	pop rdx
	pop rcx
	pop rbx
	pop rax
	pop rsi

	ret		; return

.grammar:
	db `\n[rsp+]:\t`

%endif
