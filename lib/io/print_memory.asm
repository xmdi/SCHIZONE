%ifndef PRINT_MEMORY
%define PRINT_MEMORY

; dependency
%include "lib/io/print_chars.asm"
%include "lib/io/print_int_h.asm"
%include "lib/io/print_int_d.asm"
%include "lib/io/print_int_o.asm"
%include "lib/io/print_int_b.asm"

print_memory:
; void print_memory(int {rdi}, byte* {rsi}, void* {rdx}, int {rcx});
; Prints {rcx} bytes from memory starting at {rsi} to file descriptor {rdi}. 
;	{rdx} points to the function to print integers in the desired format.

	push rsi
	push rax
	push rbx
	push rcx
	push rdx
	push rbp
	push r8
	
	mov rbp,rsi	; save initial memory location in {rbp}
	mov rbx,rdx	; save function pointer in {rbx}

.outer_loop:

	; print memory location
	mov rsi,rbp
	call print_int_h

	; print `:`
	mov rsi,.grammar
	mov rdx,1
	call print_chars

	mov r8,8	; 8 bytes per line

.inner_loop:

	; print ` `
	mov rsi,.grammar+1
	mov rdx,1
	call print_chars

	; print byte
	movzx rsi,byte [rbp]
	call rbx
	
	; go onto next byte
	inc rbp
	dec rcx
	dec r8
	jnz .inner_loop

	; print newline
	mov rsi,.grammar+2
	mov rdx,1
	call print_chars
	
	cmp rcx,0	
	jg .outer_loop

	pop r8
	pop rbp
	pop rdx
	pop rcx
	pop rbx
	pop rax
	pop rsi
	
	ret		; return

.grammar:
	db `: \n`

%endif
