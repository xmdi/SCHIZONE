%ifndef SET_FILLED_POLYGON
%define SET_FILLED_POLYGOM

; dependency
%include "lib/io/bitmap/set_pixel.asm"
%include "lib/math/int/max_int.asm"
%include "lib/math/int/min_int.asm"

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

	; find min and max y values

	push rdi
	push rsi
	push rdx

	mov rdi,r9
	mov rsi,r8
	add rsi,8
	mov rdx,8
	call min_int
	mov r10,rax	; min y in r10

	mov rdx,8
	call max_int
	mov r11,rax	; max y in r11

	pop rdx
	pop rsi
	pop rdi

	

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
