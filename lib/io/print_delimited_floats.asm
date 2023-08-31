%ifndef PRINT_DELIMITED_FLOATS
%define PRINT_DELIMITED_FLOATS

; dependency
%include "lib/io/print_chars.asm"
%include "lib/io/print_float.asm"
%include "lib/io/print_float_scientific.asm"

print_delimited_floats:
; void print_delimited_floats(uint {rdi}, double* {rsi}, uint {rdx}, uint {rcx},
;		char {r8b}, void* {r9});
; 	Prints {rdx} elements of double-precision floating-point array starting
;	at address {rsi} to file descriptor {rdi} with {rcx} significant digits
;	in scientific notation with a delimiter byte in {r8b}.

	push rsi
	push rdx
	push r10
	push r11
	sub rsp,16
	movdqu [rsp],xmm0

	; drop delimiter into temporary buffer
	mov byte [.buffer],r8b

	; track address of current element in {r10}
	mov r10,rsi

	; track number of elements remaining in {r11}
	mov r11,rdx

	jmp .delimiter_printed
	
.loop:

	; print delimiter
	mov rsi,.buffer
	mov rdx,1
	call print_chars

.delimiter_printed:

	; print value
	movsd xmm0,[r10]
	mov rsi,rcx	
	call r9

	; go onto next element
	add r10,8
	dec r11
	jnz .loop


	movdqu xmm0,[rsp]
	add rsp,16
	pop r11
	pop r10
	pop rdx
	pop rsi

	ret	

.buffer:
	db 0

%endif
