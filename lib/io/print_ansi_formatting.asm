%ifndef PRINT_ANSI_FORMATTING
%define PRINT_ANSI_FORMATTING

; dependency
%include "lib/io/print_chars.asm"

	; these are all the codes that aren't cringe
	
	; generic
	%define ANSI_CLEAR_SCREEN	0

	; formatting
	%define ANSI_RESET_FORMAT	1
	%define ANSI_BOLD		2

	; standard foreground colors
	%define ANSI_BLACK		11
	%define ANSI_RED		12
	%define ANSI_GREEN		13
	%define ANSI_YELLOW		14
	%define ANSI_BLUE		15
	%define ANSI_MAGENTA		16
	%define ANSI_CYAN		17
	%define ANSI_WHITE		18
	; bright foreground colors
	%define ANSI_BRIGHT_BLACK	19
	%define ANSI_BRIGHT_RED		20
	%define ANSI_BRIGHT_GREEN	21
	%define ANSI_BRIGHT_YELLOW	22
	%define ANSI_BRIGHT_BLUE	23
	%define ANSI_BRIGHT_MAGENTA	24
	%define ANSI_BRIGHT_CYAN	25
	%define ANSI_BRIGHT_WHITE	26

print_ansi_formatting:
; void print_ansi_formatting(int {rdi}, int {rsi});
; 	Prints escape code in {rsi} to file descriptor {rdi}.

	cmp rsi,ANSI_CLEAR_SCREEN
	jl .bogus		; return if {rsi}<0
	cmp rsi,ANSI_BRIGHT_WHITE
	jg .bogus		; return if {rsi}>26
	cmp rsi,ANSI_BLACK
	jge .good
	cmp rsi,ANSI_BOLD
	jg .bogus		; return if 2<{rsi}<11

.good:
	
	push rsi
	push rdx

	; print leading escape code
	mov rsi,.escape
	mov rdx,2
	call print_chars	

	; separate color escape codes from formatting escape codes
	mov rsi,[rsp+8]
	cmp rsi,ANSI_BLACK
	jge .print_color

.print_formatting:
	shl rsi,1
	add rsi,.formatting
	mov rdx,2
	call print_chars
	jmp .ret

.print_color:
	sub rsi,ANSI_BLACK
	shl rsi,2
	add rsi,.colors
	mov rdx,3
	call print_chars

.ret:
	pop rdx
	pop rsi

.bogus:
	ret		; return

.escape:
	db `\e[`	; escape code start
.formatting:
	db `2J`		; clear screen
	db `0m`		; reset font
	db `1m` 	; bold
.colors:
	db `30m 31m 32m 33m 34m 35m 36m 37m `
	db `90m 91m 92m 93m 94m 95m 96m 97m`

%endif
