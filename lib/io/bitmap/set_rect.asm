%ifndef SET_RECT
%define SET_RECT

; dependency
%include "lib/io/bitmap/set_line.asm"
%include "lib/io/bitmap/set_pixel.asm"

set_rect:
; void set_rect(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});
;	Draws rectangle from ({r8d},{r9d}) to ({r10d},{r11d}) (from (0,0)
;	@ top-left) in ARGB data array starting at {rdi} for an 
;	{edx}x{ecx} (WxH) image with a border color in the low 32 bits of
;	{rsi}, and a fill color in the high 32 bits of {rsi}.

	push r8
	push r9
	push r10
	push r11

	; line from (x0,y0) to (x1,y0)
	mov r11,[rsp+16]
	call set_line	

	; line from (x1,y1) to (x1,y0)
	mov r8,[rsp+8]
	mov r9,[rsp]
	call set_line

	; line from (x1,y1) to (x0,y1)
	mov r10,[rsp+24]
	mov r11,[rsp]
	call set_line

	; line from (x0,y0) to (x0,y1)
	mov r8,[rsp+24]
	mov r9,[rsp+16]
	call set_line

	mov r10,[rsp+8]
	dec r11

	push rsi
	shr rsi,32
	test rsi,rsi
	jz .ret

.loop_rows:
	inc r9
	mov r8,[rsp+32]
	inc r8
.loop_cols:
	call set_pixel
	inc r8
	cmp r8,r10
	jl .loop_cols
	cmp r9,r11
	jl .loop_rows

.ret:
	pop rsi
	pop r11
	pop r10
	pop r9
	pop r8
	ret

%endif
