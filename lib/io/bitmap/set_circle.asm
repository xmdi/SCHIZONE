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

	push rax
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push r14
	push r15

	mov r14,r8	; xc
	mov r15,r9	; yc
	mov r11,r10
	neg r11		; dx = -r
	xor r12,r12	; dy = 0
	mov r13,r11
	shl r13,1
	add r13,2	; error = 2-2r

.loop:
	; break if done
	cmp r11,0
	jge .ret

	; top right quadrant
	mov r8,r14
	sub r8,r11	
	mov r9,r15
	add r9,r12
	call set_pixel

	; top left quadrant
	mov r8,r14
	sub r8,r12	
	mov r9,r15
	sub r9,r11
	call set_pixel
	; bottom left quadrant
	mov r8,r14
	add r8,r11	
	mov r9,r15
	sub r9,r12
	call set_pixel
	; bottom right quadrant
	mov r8,r14
	add r8,r12
	mov r9,r15
	add r9,r11
	call set_pixel

;	jmp .ret
	
	mov r10,r13	; r = error
	cmp r10,r12	; if r>dy
	jg .err_above_dy
	inc r12
	mov rax,r12
	shl rax,1
	inc rax
	add r13,rax	; error += ++dy*2+1
.err_above_dy:
	cmp r10,r11	; if r<=dx, continue
	jle .loop
	cmp r13,r12	; if error<=dy, continue
	jle .loop
	inc r11
	mov rax,r11
	shl rax,1
	inc rax
	add r13,rax	; error += ++dx*2+1
	jmp .loop

.ret:
	pop r15
	pop r14		
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rax

	ret

%endif
