%ifndef SET_FILLED_RECT
%define SET_FILLED_RECT

; dependency
%include "lib/io/bitmap/set_line.asm"

set_filled_rect:
; void set_filled_rect(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});
;	Draws rectangle from ({r8d},{r9d}) to ({r10d},{r11d}) (from (0,0)
;	@ top-left) in ARGB data array starting at {rdi} for an 
;	{edx}x{ecx} (WxH) image with a fill color in the low 32 bits of {rsi}.

	push r8
	push r9
	push r10
	push r11
	push rax

	cmp r11,r9
	jg .top_down
	mov rax,-1
	jmp .start
.top_down:
	mov rax,1
.start:

	mov r11,r9

	; loop thru all rows
.loop:

	call set_line

	add r9,rax
	add r11,rax

	cmp r9,[rsp+8]
	jne .loop

	call set_line

.ret:
	pop rax
	pop r11
	pop r10
	pop r9
	pop r8
	ret

%endif
