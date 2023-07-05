%ifndef PRINT_STRING
%define PRINT_STRING

; dependency
%include "lib/io/print_chars.asm"

print_string:
; void print_string(int {rdi}, char* {rsi});
; 	Writes null-terminated char array starting at {rsi} to file 
;	descriptor {rdi}.

	push rdx		; save register

	; calculate the length of the null-terminated string
	mov rdx,-1		; set strlen counter to -1
.print_string_loop:
	inc rdx			; increase the counter by 1
	cmp byte [rsi+rdx],0	; check if the byte is null
	jne .print_string_loop	; if not, try the next one

	call print_chars

	pop rdx			; restore register

	ret

%endif
