%ifndef SET_FILLED_POLYGON
%define SET_FILLED_POLYGOM

; dependency
%include "lib/io/bitmap/set_pixel.asm"

set_filled_polygon:
; void set_filled_polygon(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 double* {r8}, int {r9});
;	Draws filled polygon with {r9} vertices in 2*{r9} length long (8-byte) int array at {r8}
;	to ARGB data array starting at {rdi} for an
;	{edx}x{ecx} (WxH) image with a fill color in the low 32 bits of {rsi}.

	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push rax





.ret:
	pop rax
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	ret

%endif
