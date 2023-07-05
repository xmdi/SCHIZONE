%ifndef ANSI_MOVE_CURSOR
%define ANSI_MOVE_CURSOR

; dependency
%include "lib/io/print_chars.asm"
%include "lib/io/print_int_d.asm"
	
ansi_move_cursor:
; void ansi_move_cursor(int {rdi}, int {rsi}, int {rdx});
; 	Moves cursor to position ({rsi},{rdx}) in file descriptor {rdi}.

	push rsi
	push rdx
	
	mov rsi,.code
	mov rdx,2
	call print_chars	

	mov rsi,[rsp]
	call print_int_d

	mov rsi,.code+2
	mov rdx,1
	call print_chars

	mov rsi,[rsp+8]
	call print_int_d
	
	mov rsi,.code+3
	mov rdx,1
	call print_chars

	pop rdx
	pop rsi
	
	ret

.code:
	db `\e[;H`

%endif
