%ifndef SET_TRIANGLE_DEPTH
%define SET_TRIANGLE_DEPTH

; dependency
%include "lib/io/bitmap/set_pixel.asm"
%include "lib/math/vector/dot_product_3.asm"
%include "lib/math/vector/triangle_normal.asm"
%include "lib/mem/memcopy.asm"

set_triangle_depth:
; void set_triangle_depth(void* {rdi}, long*/long {rsi}, int {edx}, int {ecx},
;		 double* {r8}, bool {r9}, single* {r10})
;	Fills triangle with vertices described by 9 double-precision floats
;	starting at {r8} (projected x, projected y, projected depth)
;	in ARGB data array starting at {rdi} for an {edx}x{ecx} (WxH) image. 
;	{r9} contains color interpolation flag. If low bit of {r9} is high, 
;	{rsi} points to 3x1 ARGB color array (32 bpp). If low bit of {r9} 
;	is low, {rsi} contains triangle fill color (32 bpp). Pointer to 
;	single-precision depth buffer at {r10} (4*{ecx}*{edx} bytes). 

	push rax
	push rbx
	push rbp
	push rsi
	push r8
	push r9
	push r13
	push r14
	push r15
	sub rsp,256
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
	movdqu [rsp+176],xmm11
	movdqu [rsp+192],xmm12
	movdqu [rsp+208],xmm13
	movdqu [rsp+224],xmm14
	movdqu [rsp+240],xmm15

	push rdi
	push rsi
	push rdx
	push rcx

	mov rdi,.vertices_copy
	mov rsi,r8
	mov rdx,9*8
	call memcopy

	xor rdx,rdx
	mov [.vertices_copy+16],rdx
	mov [.vertices_copy+40],rdx
	mov [.vertices_copy+64],rdx

	mov rdi,.triangle_normal
	mov rsi,.vertices_copy+0
	mov rdx,.vertices_copy+24
	mov rcx,.vertices_copy+48
	call triangle_normal

	pxor xmm1,xmm1
	movsd xmm0,[.triangle_normal+16]
	comisd xmm0,xmm1
	jb .skip

	mov rdi,.triangle_normal
	mov rsi,.triangle_normal
	call dot_product_3

	sqrtsd xmm0,xmm0
;	mulsd xmm0,[.neg_one]
	movsd xmm1,[.neg_one]
	divsd xmm1,xmm0
	
	movsd [.scale_factor],xmm1
	
	pop rcx
	pop rdx
	pop rsi
	pop rdi


	mov r15,rsi

	movsd xmm12,[r8+0]	; min vtx 1 x
	minsd xmm12,[r8+24]	; min vtx 2 x
	minsd xmm12,[r8+48]	; min vtx 3 x
	roundsd xmm12,xmm12,0b0001
	movsd xmm13,[r8+0]	; max vtx 1 x
	maxsd xmm13,[r8+24]	; max vtx 2 x
	maxsd xmm13,[r8+48]	; max vtx 3 x
	roundsd xmm13,xmm13,0b0010
	movsd xmm14,[r8+8]	; min vtx 1 y
	minsd xmm14,[r8+32]	; min vtx 2 y
	minsd xmm14,[r8+56]	; min vtx 3 y
	roundsd xmm14,xmm14,0b0001
	movsd xmm15,[r8+8]	; max vtx 1 y
	maxsd xmm15,[r8+32]	; max vtx 2 y
	maxsd xmm15,[r8+56]	; max vtx 3 y
	roundsd xmm15,xmm15,0b0010

	; check if triangle is off the screen
	pxor xmm0,xmm0	
	comisd xmm15,xmm0 ; max y
	jb .off_screen
	comisd xmm13,xmm0 ; max x
	jb .off_screen
	cvtsi2sd xmm0,[framebuffer_init.framebuffer_width]
	comisd xmm12,xmm0 ; min x
	ja .off_screen
	cvtsi2sd xmm0,[framebuffer_init.framebuffer_height]
	comisd xmm14,xmm0 ; min y
	ja .off_screen

	movsd xmm0,[r8+24]
	subsd xmm0,[r8+0]
	movsd [.vtx0_to_vtx1+0],xmm0
	movsd xmm0,[r8+32]
	subsd xmm0,[r8+8]
	movsd [.vtx0_to_vtx1+8],xmm0

	movsd xmm0,[r8+48]
	subsd xmm0,[r8+24]
	movsd [.vtx1_to_vtx2+0],xmm0
	movsd xmm0,[r8+56]
	subsd xmm0,[r8+32]
	movsd [.vtx1_to_vtx2+8],xmm0

	movsd xmm0,[r8+0]
	subsd xmm0,[r8+48]
	movsd [.vtx2_to_vtx0+0],xmm0
	movsd xmm0,[r8+8]
	subsd xmm0,[r8+56]
	movsd [.vtx2_to_vtx0+8],xmm0

	pxor xmm9,xmm9
	movsd xmm11,xmm14

	; pt to check/plot at ({xmm10},{xmm11}) ; could be ints and constantly converted via cvtsi2sd

.rect_loop_y:

	xor al,al
	mov byte [.line_test],al

	; check if y value is within bounds 0<=xmm11<=screen_height
	pxor xmm0,xmm0
	comisd xmm11,xmm0
	jb .skip_row
	cvtsi2sd xmm0,rcx
	comisd xmm11,xmm0
	jae .skip_row ; maybe just 'ja'

	movsd xmm10,xmm12

.rect_loop_x:

	; check if x value is within bounds 0<=xmm10<=screen_width
	pxor xmm0,xmm0
	comisd xmm10,xmm0
	jb .skip_col
	cvtsi2sd xmm0,rdx
	comisd xmm10,xmm0
	jae .skip_col ; maybe just 'ja'

	; check edges	

	; cross product of vtx0->pt and vtx0->vtx1	
	; pt-vtx0
	movsd xmm1,xmm10
	subsd xmm1,[r8+0] ; todo x and y can be parallelized here
	movsd xmm0,xmm11
	subsd xmm0,[r8+8]
	; vtx1-vtx0
	movsd xmm3,[.vtx0_to_vtx1+0]
	movsd xmm2,[.vtx0_to_vtx1+8]
	mulsd xmm1,xmm2
	mulsd xmm0,xmm3
	subsd xmm1,xmm0
	comisd xmm1,xmm9
	ja .point_no_good ; might need to be ja
	movsd xmm6,xmm1	 	; {xmm6} contains barycentric coefficient w

	; cross product of vtx1->pt and vtx1->vtx2	
	; pt-vtx1
	movsd xmm1,xmm10
	subsd xmm1,[r8+24] ; todo x and y can be parallelized here
	movsd xmm0,xmm11
	subsd xmm0,[r8+32]
	; vtx2-vtx1	
	movsd xmm3,[.vtx1_to_vtx2+0]
	movsd xmm2,[.vtx1_to_vtx2+8]
	mulsd xmm1,xmm2
	mulsd xmm0,xmm3
	subsd xmm1,xmm0
	comisd xmm1,xmm9
	ja .point_no_good ; might need to be ja
	movsd xmm4,xmm1	 	; {xmm4} contains barycentric coefficient u

	; cross product of vtx2->pt and vtx2->vtx0	
	; pt-vtx2
	movsd xmm1,xmm10
	subsd xmm1,[r8+48] ; todo x and y can be parallelized here
	movsd xmm0,xmm11
	subsd xmm0,[r8+56]
	; vtx0-vtx2p	
	movsd xmm3,[.vtx2_to_vtx0+0]
	movsd xmm2,[.vtx2_to_vtx0+8]
	mulsd xmm1,xmm2
	mulsd xmm0,xmm3
	subsd xmm1,xmm0
	comisd xmm1,xmm9
	ja .point_no_good ; might need to be ja
	movsd xmm5,xmm1	 	; {xmm5} contains barycentric coefficient v

.point_in_triangle:

	mov al,1
	mov byte [.line_test],al

	mulsd xmm4,[.scale_factor]
	mulsd xmm5,[.scale_factor]
	mulsd xmm6,[.scale_factor]
	

	;	barycentric coordinates for point in triangle at
	;		( {xmm4} , {xmm5} , {xmm6} )

	; compute depth at this point first
	; {xmm4}*[r8+16] + {xmm5}*[r8+40] + {xmm6}*[r8+64]

	movsd xmm0,xmm4
	movsd xmm1,xmm5
	movsd xmm2,xmm6
	mulsd xmm0,[r8+16]	
	mulsd xmm1,[r8+40]	
	mulsd xmm2,[r8+64]	
	addsd xmm0,xmm1
	addsd xmm0,xmm2

	; depth of pixel of interest in {xmm0} (double precision)

	cvtsd2ss xmm0,xmm0 ; might not work LOL

	cvtsd2si rax,xmm10 ; x coord
	cvtsd2si rbx,xmm11 ; y coord

	mov rbp,rbx
	imul rbp,rdx
	add rbp,rax
	shl rbp,2 ; {rbp} contains byte number for pixel of interest
	add rbp,r10	; {rbp} points to depth for pixel of interest
.test_label:
	movss xmm1,[rbp]

	comiss xmm0,xmm1
	jbe .too_deep_to_put_pixel
	
	; overwrite depth
	movss [rbp],xmm0

	; compute color at this point
	cmp r9,0 ; TODO should be a test instruction tbh, not cmp
	je .color_computed

;	mov r13,0x100000000
	xor r13,r13

	; {xmm4}*[r8+16] + {xmm5}*[r8+40] + {xmm6}*[r8+64]
	mov r14,[r15+0]
	shr r14,24
	and r14,0xFF
	cvtsi2sd xmm0,r14
	mov r14,[r15+8]
	shr r14,24
	and r14,0xFF
	cvtsi2sd xmm1,r14
	mov r14,[r15+16]
	shr r14,24
	and r14,0xFF
	cvtsi2sd xmm2,r14
	mulsd xmm0,xmm4
	mulsd xmm1,xmm5	
	mulsd xmm2,xmm6
	addsd xmm0,xmm1
	addsd xmm0,xmm2
	cvtsd2si r14,xmm0
	shl r14,24
	add r13,r14

	mov r14,[r15+0]
	shr r14,16
	and r14,0xFF
	cvtsi2sd xmm0,r14
	mov r14,[r15+8]
	shr r14,16
	and r14,0xFF
	cvtsi2sd xmm1,r14
	mov r14,[r15+16]
	shr r14,16
	and r14,0xFF
	cvtsi2sd xmm2,r14
	mulsd xmm0,xmm4
	mulsd xmm1,xmm5	
	mulsd xmm2,xmm6
	addsd xmm0,xmm1
	addsd xmm0,xmm2
	cvtsd2si r14,xmm0
	shl r14,16
	add r13,r14

	mov r14,[r15+0]
	shr r14,8
	and r14,0xFF
	cvtsi2sd xmm0,r14
	mov r14,[r15+8]
	shr r14,8
	and r14,0xFF
	cvtsi2sd xmm1,r14
	mov r14,[r15+16]
	shr r14,8
	and r14,0xFF
	cvtsi2sd xmm2,r14
	mulsd xmm0,xmm4
	mulsd xmm1,xmm5	
	mulsd xmm2,xmm6
	addsd xmm0,xmm1
	addsd xmm0,xmm2
	cvtsd2si r14,xmm0
	shl r14,8
	add r13,r14

	mov r14,[r15+0]
	and r14,0xFF
	cvtsi2sd xmm0,r14
	mov r14,[r15+8]
	and r14,0xFF
	cvtsi2sd xmm1,r14
	mov r14,[r15+16]
	and r14,0xFF
	cvtsi2sd xmm2,r14
	mulsd xmm0,xmm4
	mulsd xmm1,xmm5	
	mulsd xmm2,xmm6
	addsd xmm0,xmm1
	addsd xmm0,xmm2
	cvtsd2si r14,xmm0
	add r13,r14

	mov rsi,r13 ; color of pixel of interest in {rsi}
	
.color_computed:
	; put the pixel

	push r8
	push r9
	mov r8,rax
	mov r9,rbx
	call set_pixel
	pop r9
	pop r8

.too_deep_to_put_pixel:

	jmp .skip_col

.point_no_good:
	
	; if line_test = 1, skip to next row
	cmp word [.line_test],1
	je .skip_row
	
	; pt to check/plot at ({xmm10},{xmm11}) ; could be ints and constantly converted via cvtsi2sd
.skip_col:

	addsd xmm10,[.one]
	comisd xmm10,xmm13
	jb .rect_loop_x

.skip_row:
	addsd xmm11,[.one]
	comisd xmm11,xmm15
	jb .rect_loop_y

.off_screen:

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
	movdqu xmm11,[rsp+176]
	movdqu xmm12,[rsp+192]
	movdqu xmm13,[rsp+208]
	movdqu xmm14,[rsp+224]
	movdqu xmm15,[rsp+240]
	add rsp,256
	pop r15
	pop r14
	pop r13
	pop r9
	pop r8
	pop rsi
	pop rbp
	pop rbx
	pop rax
	
	ret

.skip:
	pop rcx
	pop rdx
	pop rsi
	pop rdi
	jmp .off_screen

.one:
	dq 1.0
.neg_one:
	dq -1.0
.scale_factor:
	dq 0.0
.vtx_to_pt:
	times 2 dq 0.0
.vtx0_to_vtx1:
	times 2 dq 0.0
.vtx1_to_vtx2:
	times 2 dq 0.0
.vtx2_to_vtx0:
	times 2 dq 0.0
.vertices_copy:
	times 9 dq 0.0
.triangle_normal:
	times 3 dq 0.0
.line_test:
	db 0
%endif
