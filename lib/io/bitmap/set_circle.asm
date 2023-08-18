%ifndef SET_CIRCLE
%define SET_CIRCLE

; dependency
%include "lib/io/bitmap/set_pixel.asm"

set_circle:
; void set_circle(void* {rdi}, int {esi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d});
;	Draws circle of radius {r10d} around ({r8d},{r9d}) (from (0,0)
;	@ top-left) in ARGB data array starting at {rdi} for an 
;	{edx}x{ecx} (WxH) image in the color value in {esi}.

	push r8
	push r9
	push r11
	push r12
	push r13
	push r14
	push r15

	mov r11,r8	; save xc in {r11}
	mov r12,r9	; save yc in {r12}
	mov r13,r10
	shl r13,1
	neg r13
	add r13,3	; D = 3-2r

	xor r14,r14	; dx = 0
	mov r15,r10	; dy = r

.loop:
	cmp r14,r15	; break if dx>=dy
	jg .ret

	mov r8,r11
	add r8,r14
	mov r9,r12
	add r9,r15
	call set_pixel	; pixel @ (xc+dx,yc+dy)
	mov r8,r11
	sub r8,r14
	mov r9,r12
	add r9,r15
	call set_pixel	; pixel @ (xc-dx,yc+dy)
	mov r8,r11
	add r8,r14
	mov r9,r12
	sub r9,r15
	call set_pixel	; pixel @ (xc+dx,yc-dy)
	mov r8,r11
	sub r8,r14
	mov r9,r12
	sub r9,r15
	call set_pixel	; pixel @ (xc-dx,yc-dy)
	mov r8,r11
	add r8,r15
	mov r9,r12
	add r9,r14
	call set_pixel	; pixel @ (xc+dy,yc+dx)
	mov r8,r11
	sub r8,r15
	mov r9,r12
	add r9,r14
	call set_pixel	; pixel @ (xc-dy,yc+dx)
	mov r8,r11
	add r8,r15
	mov r9,r12
	sub r9,r14
	call set_pixel	; pixel @ (xc+dy,yc-dx)
	mov r8,r11
	sub r8,r15
	mov r9,r12
	sub r9,r14
	call set_pixel	; pixel @ (xc-dy,yc-dx)

	test r13,r13
	js .dy_unchanged
	mov r8,r14
	sub r8,r15
	shl r8,2
	add r8,10
	add r13,r8	; D+=(4(dx-dy)+10)
	inc r14		; dx++
	dec r15		; dy--
	jmp .loop
.dy_unchanged:
	mov r8,r14
	shl r8,2
	add r8,6
	add r13,r8	; D+=(4dx+6)
	inc r14		; dx++
	jmp .loop

.ret:
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r9
	pop r8

	ret

%endif
