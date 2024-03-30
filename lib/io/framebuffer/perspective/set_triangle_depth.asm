%ifndef SET_TRIANGLE_DEPTH
%define SET_TRIANGLE_DEPTH

; dependency
%include "lib/io/bitmap/set_pixel.asm"
%include "lib/math/vector/cross_product_3.asm"
%include "lib/math/vector/dot_product_3.asm"

set_triangle:
; void set_triangle(void* {rdi}, int {esi}, int {edx}, int {ecx},
;		 double* {r8}, int {r9d}, int {r10d}, int {r11d});
;	Fills triangle with vertices described by 6 double-precision floats
;	starting at {r8} in ARGB data array starting at {rdi} for an 
;	{edx}x{ecx} (WxH) image in the color value in {esi}. TODO handle 
;	interpolated coloring per colors stored alongside vertex data.

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

	movsd xmm12,[r8+0]	; min vtx 1 x
	minsd xmm12,[r8+16]	; min vtx 2 x
	minsd xmm12,[r8+32]	; min vtx 3 x
	movsd xmm13,[r8+0]	; max vtx 1 x
	maxsd xmm13,[r8+16]	; max vtx 2 x
	maxsd xmm13,[r8+32]	; max vtx 3 x
	
	movsd xmm14,[r8+8]	; min vtx 1 y
	minsd xmm14,[r8+24]	; min vtx 2 y
	minsd xmm14,[r8+40]	; min vtx 3 y
	movsd xmm15,[r8+8]	; max vtx 1 y
	maxsd xmm15,[r8+24]	; max vtx 2 y
	maxsd xmm15,[r8+40]	; max vtx 3 y

	; check if triangle is off the screen
	pxor xmm0,xmm0	
	comisd xmm15,xmm0
	jb .off_screen
	comisd xmm13,xmm0
	jb .off_screen
	cvtsi2sd xmm0,rdx
	comisd xmm12,xmm0
	ja .off_screen
	cvtsi2sd xmm0,rcx
	comisd xmm14,xmm0
	ja .off_screen

	; populate vtx_to_vtx arrays
	movpd xmm0,[r8+16]
	subpd xmm0,[r8+0]
	movpd [.vtx0_to_vtx1],xmm0
	movpd xmm0,[r8+32]
	subpd xmm0,[r8+16]
	movpd [.vtx1_to_vtx2],xmm0
	movpd xmm0,[r8+0]
	subpd xmm0,[r8+32]
	movpd [.vtx2_to_vtx0],xmm0

	pxor xmm9,xmm9
	movsd xmm11,xmm14

	; pt to check/plot at ({xmm10},{xmm11})

.rect_loop_y:

	movsd xmm10,xmm12

.rect_loop_x:

	; check edges	

	; cross product of vtx0->pt and vtx0->vtx1	
	movsd xmm0,xmm10
	subsd xmm0,[r8+0] ; todo x and y can be parallelized here
	movsd [.vtx_to_pt],xmm0
	movsd xmm0,xmm11
	subsd xmm0,[r8+8]
	movsd [.vtx_to_pt],xmm0
	
	comisd xmm0,xmm9
	





.point_no_good:

	addsd xmm10,[.one]
	comisd xmm10,xmm13
	jb .rect_loop_x

	addsd xmm11,[.one]
	comisd xmm11,xmm15
	jb .rect_loop_y







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

.off_screen:
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

.one
	dq 1.0

.vtx_to_pt:
	times 2 dq 0.0
.vtx0_to_vtx1:
	times 2 dq 0.0
.vtx1_to_vtx2:
	times 2 dq 0.0
.vtx2_to_vtx0:
	times 2 dq 0.0

%endif
