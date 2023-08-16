%ifndef SET_LINE
%define SET_LINE

; dependency
%include "lib/io/bitmap/set_pixel.asm"

set_line:
; void set_line(void* {rdi}, int {esi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});
;	Draws line from ({r8d},{r9d}) to ({r10d},{r11d}) (from (0,0)
;	@ top-left) in ARGB data array starting at {rdi} for an 
;	{edx}x{ecx} (HxW) image in the color value in {esi}.
	
	push rbx
	push r8
	push r9
	push r12
	push r13

	mov r12,r10
	sub r12,r8	; {r12} = dx = x1-x0
	mov r13,r11
	sub r13,r9	; {r13} = dy = y1-y0
	shl r13,1	; {r13} = 2*dy = 2*(y1-y0)

	mov rbx,r13
	sub rbx,r12	; {rbx} = D = 2*dy-dx
	shl r12,1	; {r12} = 2*dx = 2*(x1-x0)

	; loop x from x0 to x1 in {r8}
	; track y in {r9}
.loop:
	call set_pixel	; set the pixel at (x,y)
	cmp rbx,0
	jle .dont_adjust_y
.adjust_y:
	sub rbx,r12	; D -= 2*dx 
	inc r9		; y++
	jmp .go_next
.dont_adjust_y:
	add rbx,r13	; D += 2*dy
.go_next:
	inc r8		; x++
	cmp r8,r10
	jle .loop

	pop r13
	pop r12
	pop r9
	pop r8
	pop rbx

	ret		; return

%endif
