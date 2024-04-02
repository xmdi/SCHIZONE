%ifndef SET_TRIANGLE_DEPTH
%define SET_TRIANGLE_DEPTH

; dependency
%include "lib/io/bitmap/set_pixel.asm"

set_triangle_depth:
; void set_triangle_depth(void* {rdi}, long*/long {rsi}, int {edx}, int {ecx},
;		 double* {r8}, bool {r9})
;	Fills triangle with vertices described by 6 double-precision floats
;	starting at {r8} in ARGB data array starting at {rdi} for an 
;	{edx}x{ecx} (WxH) image. {r9} contains color interpolation flag. If 
;	low bit of {r12} is high, {rsi} points to 3x1 ARGB color array 
;	(32 bpp). If low bit of {r9} is low, {rsi} contains triangle fill
;	color (32 bpp).

	push rax
	push r8
	push r9
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
	roundsd xmm12,xmm12,0b0001
	movsd xmm13,[r8+0]	; max vtx 1 x
	maxsd xmm13,[r8+16]	; max vtx 2 x
	maxsd xmm13,[r8+32]	; max vtx 3 x
	roundsd xmm13,xmm13,0b0010
	movsd xmm14,[r8+8]	; min vtx 1 y
	minsd xmm14,[r8+24]	; min vtx 2 y
	minsd xmm14,[r8+40]	; min vtx 3 y
	roundsd xmm14,xmm14,0b0001
	movsd xmm15,[r8+8]	; max vtx 1 y
	maxsd xmm15,[r8+24]	; max vtx 2 y
	maxsd xmm15,[r8+40]	; max vtx 3 y
	roundsd xmm15,xmm15,0b0010

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

	; pt to check/plot at ({xmm10},{xmm11}) ; could be ints and constantly converted via cvtsi2sd

.rect_loop_y:

	movsd xmm10,xmm12

.rect_loop_x:

	; check edges	

	; cross product of vtx0->pt and vtx0->vtx1	
	; pt-vtx0
	movsd xmm1,xmm10
	subsd xmm1,[r8+0] ; todo x and y can be parallelized here
	movsd xmm0,xmm11
	subsd xmm0,[r8+8]
	; vtx1-vtx0
	movsd xmm3,[r8+16]
	subsd xmm3,[r8+0]
	movsd xmm2,[r8+24]
	subsd xmm2,[r8+8]
	mulsd xmm1,xmm2
	mulsd xmm0,xmm3
	subsd xmm1,xmm0
	comisd xmm1,xmm9
	jb .point_no_good ; might need to be ja
	movsd xmm4,xmm1	 	; {xmm4} contains barycentric coefficient w

	; cross product of vtx1->pt and vtx1->vtx2	
	; pt-vtx1
	movsd xmm1,xmm10
	subsd xmm1,[r8+16] ; todo x and y can be parallelized here
	movsd xmm0,xmm11
	subsd xmm0,[r8+24]
	; vtx2-vtx1
	movsd xmm3,[r8+32]
	subsd xmm3,[r8+16]
	movsd xmm2,[r8+40]
	subsd xmm2,[r8+24]
	mulsd xmm1,xmm2
	mulsd xmm0,xmm3
	subsd xmm1,xmm0
	comisd xmm1,xmm9
	jb .point_no_good ; might need to be ja
	movsd xmm5,xmm1	 	; {xmm5} contains barycentric coefficient u

	; cross product of vtx2->pt and vtx2->vtx0	
	; pt-vtx2
	movsd xmm1,xmm10
	subsd xmm1,[r8+32] ; todo x and y can be parallelized here
	movsd xmm0,xmm11
	subsd xmm0,[r8+40]
	; vtx0-vtx2
	movsd xmm3,[r8+0]
	subsd xmm3,[r8+32]
	movsd xmm2,[r8+8]
	subsd xmm2,[r8+40]
	mulsd xmm1,xmm2
	mulsd xmm0,xmm3
	subsd xmm1,xmm0
	comisd xmm1,xmm9
	jb .point_no_good ; might need to be ja
	movsd xmm6,xmm1	 	; {xmm6} contains barycentric coefficient v
	
.point_in_triangle:
	;	barycentric coordinates for point in triangle at
	;		( {xmm4} , {xmm5} , {xmm6} )







.point_no_good:

	addsd xmm10,[.one]
	comisd xmm10,xmm13
	jb .rect_loop_x

	addsd xmm11,[.one]
	comisd xmm11,xmm15
	jb .rect_loop_y








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
