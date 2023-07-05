%ifndef PRINT_REGISTERS
%define PRINT_REGISTERS

; dependency
%include "lib/io/print_chars.asm"
%include "lib/io/print_int_d.asm"
%include "lib/io/print_int_h.asm"
%include "lib/io/print_int_o.asm"
%include "lib/io/print_int_b.asm"

print_registers:
; void print_registers(int [rsp+8], int [rsp+16]);
; 	Prints out register values to file descriptor [rsp+8] using the print 
;	function pointer in [rsp+16],
;	(eg, print_int_b, print_int_h, print_int_d).

	mov [.initial_stack],rsp	; copout to avoid math

	; save all registers
	push r15
	push r14
	push r13	
	push r12	
	push r11	
	push r10	
	push r9	
	push r8	
	push rdi	
	push rsi	
	push rbp	
	mov r8,[.initial_stack] ; initial {rsp}
	push r8	
	push rdx	
	push rcx	
	push rbx	
	push rax	
	
	mov rdi,[.initial_stack]
	add rdi,8
	mov rdi,[rdi]		; {rdi} containts output file descriptor
	mov rcx,.register_names ; {rcx} points to current register string start
	mov rdx,5		; each string is 5 chars	
	mov rbx,[.initial_stack]
	add rbx,16
	mov rbx,[rbx]		; {rbx} contains print function pointer
	mov rbp,rsp

.loop:
	; print the current register string
	mov rsi,rcx
	mov rdx,5
	call print_chars

	; then pop off current register value & print
	mov rsi,[rbp]
	call rbx
	add rbp,8

	; move to next register in string
	add rcx,5
	cmp rcx,.register_names+80
	jl .loop	; loop until done

	; print one final newline
	mov rsi,.register_names
	mov rdx,1
	call print_chars

	; restore all registers
	pop rax
	pop rbx
	pop rcx	
	pop rdx
	add rsp,8	; skip popping rsp	
	pop rbp	
	pop rsi	
	pop rdi	
	pop r8	
	pop r9	
	pop r10	
	pop r11	
	pop r12	
	pop r13	
	pop r14	
	pop r15	

	ret		; return

.register_names:
	db `\nrax=\nrbx=\nrcx=\nrdx=\nrsp=\nrbp=\nrsi=\nrdi=`
	db `\nr8 =\nr9 =\nr10=\nr11=\nr12=\nr13=\nr14=\nr15=`

.initial_stack:
	dq 0

%endif
