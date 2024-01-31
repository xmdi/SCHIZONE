%ifndef SET_TRIANGLE
%define SET_TRIANGLE

; dependency
%include "lib/io/bitmap/set_line.asm"

set_triangle:
; void set_triangle(void* {rdi}, int {esi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});
;	Draws triangle with vertices at ({r8d},{r9d}), ({r10d},{r11d}),
;	and ({r12d},{r13d}) (from (0,0)	@ top-left) in ARGB data array 
;	starting at {rdi} for an {edx}x{ecx} (WxH) image in the color 
;	value in {esi}.

	push rax
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	sub rsp,176
	movdqu [rsp+0],xmm0
	movdqu [rsp+16],xmm1
	movdqu [rsp+32],xmm2
	movdqu [rsp+48],xmm3
	movdqu [rsp+64],xmm4
	movdqu [rsp+80],xmm5
	movdqu [rsp+96],xmm6
	movdqu [rsp+112],xmm7
	movdqu [rsp+128],xmm8
	movdqu [rsp+144],xmm9
	movdqu [rsp+160],xmm10

	; want r9<=r11
	; want r11<=r13
	; want r9<=r11

	; need to sort the vertices top to bottom; TODO IMPROVE
	cmp r9d,r11d
	jle .dont_swap_first_two
	mov eax,r11d
	mov r11d,r9d
	mov r9d,eax
	mov eax,r10d
	mov r10d,r8d
	mov r8d,eax
.dont_swap_first_two:
	cmp r11d,r13d
	jle .dont_swap_second_two
	mov eax,r13d
	mov r13d,r11d
	mov r11d,eax
	mov eax,r12d
	mov r12d,r10d
	mov r10d,eax
.dont_swap_second_two:
	cmp r9d,r11d
	jle .dont_swap_last_two
	mov eax,r11d
	mov r11d,r9d
	mov r9d,eax
	mov eax,r10d
	mov r10d,r8d
	mov r8d,eax
.dont_swap_last_two:

	; now do a flat-top triangle starting at the lowest point

	cvtsi2sd xmm0,r13; Ay
	cvtsi2sd xmm1,r12; Ax
	cvtsi2sd xmm2,r11; By
	cvtsi2sd xmm3,r10; Bx
	cvtsi2sd xmm4,r9; Cy
	cvtsi2sd xmm5,r8; Cx

	;side1 inverse slope = (Bx-Ax)/(By-Ay)
	movsd xmm6,xmm3
	subsd xmm6,xmm1
	movsd xmm7,xmm2
	subsd xmm7,xmm0
	divsd xmm6,xmm7

	;side2 inverse slope = (Cx-Ax)/(Cy-Ay)
	movsd xmm8,xmm5
	subsd xmm8,xmm1
	movsd xmm9,xmm4
	subsd xmm9,xmm0
	divsd xmm8,xmm9

	; side 1 x = side 2 x at the top
	movsd xmm7,xmm1
	movsd xmm9,xmm1

	cmp r13,r11
	jg .loop1

	; if we don't have a bottom part to our triangle	
	movsd xmm7,xmm3
	movsd xmm9,xmm1
	jmp .end_loop1

.loop1:
	
	push r8
	push r9
	push r10
	push r11
	cvtsd2si r8,xmm7
	cvtsd2si r10,xmm9

 	mov r9,r13
	mov r11,r13
	call set_line
	pop r11
	pop r10
	pop r9
	pop r8

	subsd xmm7,xmm6
	subsd xmm9,xmm8

	dec r13
	cmp r13,r11
	jge .loop1

	addsd xmm7,xmm6

.end_loop1:

	;side1 inverse slope = (Cx-Bx)/(Cy-By)
	movsd xmm6,xmm5
	subsd xmm6,xmm3
	movsd xmm10,xmm4
	subsd xmm10,xmm2
	divsd xmm6,xmm10

	cmp r13,r9
	jle .ret

.loop2:
	
	push r8
	push r9
	push r10
	push r11
	cvtsd2si r8,xmm7
	cvtsd2si r10,xmm9
 	mov r9,r13
	mov r11,r13
	call set_line
	pop r11
	pop r10
	pop r9
	pop r8

	subsd xmm7,xmm6
	subsd xmm9,xmm8


	dec r13
	cmp r13,r9
	jge .loop2

.ret:

	movdqu xmm0,[rsp+0]
	movdqu xmm1,[rsp+16]
	movdqu xmm2,[rsp+32]
	movdqu xmm3,[rsp+48]
	movdqu xmm4,[rsp+64]
	movdqu xmm5,[rsp+80]
	movdqu xmm6,[rsp+96]
	movdqu xmm7,[rsp+112]
	movdqu xmm8,[rsp+128]
	movdqu xmm9,[rsp+144]
	movdqu xmm10,[rsp+160]
	add rsp,176
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rax
	
	ret

%endif
