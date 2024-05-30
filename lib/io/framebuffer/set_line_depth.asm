%ifndef SET_LINE_DEPTH
%define SET_LINE_DEPTH

; dependency
%include "lib/io/bitmap/set_pixel.asm"
%include "lib/math/vector/dot_product_3.asm"
%include "lib/math/vector/triangle_normal.asm"
%include "lib/mem/memcopy.asm"

set_line_depth:
; void set_line_depth(void* {rdi}, long*/long {rsi}, int {edx}, int {ecx},
;		 double* {r8}, bool {r9}, single* {r10})
;	Plots line with vertices described by 6 double-precision floats
;	starting at {r8} (projected x, projected y, projected depth)
;	in ARGB data array starting at {rdi} for an {edx}x{ecx} (WxH) image. 
;	{r9} contains color interpolation flag. If low bit of {r9} is high, 
;	{rsi} points to 3x1 ARGB color array (32 bpp). If low bit of {r9} 
;	is low, {rsi} contains solid line color (32 bpp). Pointer to 
;	single-precision depth buffer at {r10} (4*{ecx}*{edx} bytes). 

	push rax
	push rbx
	push rbp
	push rsi
	push r8
	push r9
	push r10
	push r11
	push r12
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

	mov rbp,r9	; save color boolean from clobberin'

	mov r15,rsi
	
	movsd xmm12,[r8+0]	; min vtx 1 x
	minsd xmm12,[r8+24]	; min vtx 2 x
	roundsd xmm12,xmm12,0b0001
	movsd xmm13,[r8+0]	; max vtx 1 x
	maxsd xmm13,[r8+24]	; max vtx 2 x
	roundsd xmm13,xmm13,0b0010
	movsd xmm14,[r8+8]	; min vtx 1 y
	minsd xmm14,[r8+32]	; min vtx 2 y
	roundsd xmm14,xmm14,0b0001
	movsd xmm15,[r8+8]	; max vtx 1 y
	maxsd xmm15,[r8+32]	; max vtx 2 y
	roundsd xmm15,xmm15,0b0010
	
	; check if line is entirely off the screen
	pxor xmm0,xmm0	
	comisd xmm15,xmm0 ; max y
	jb .ret
	comisd xmm13,xmm0 ; max x
	jb .ret
	cvtsi2sd xmm0,[framebuffer_init.framebuffer_width]
	comisd xmm12,xmm0 ; min x
	ja .ret
	cvtsi2sd xmm0,[framebuffer_init.framebuffer_height]
	comisd xmm14,xmm0 ; min y
	ja .ret

	pxor xmm9,xmm9
	movsd xmm11,xmm14

	; pt to check/plot at ({xmm10},{xmm11}) ; could be ints and constantly converted via cvtsi2sd

	;;;;;; todo, adjust line endpoints to be within screen boundary
	;;;;;; oops nvm for gradient
	
	movsd xmm1,[r8+16]; z0
	movsd xmm3,[r8+40]; z1
	movsd xmm0,[r8+32]; y1
	cvtsd2si r11,xmm0
	movsd xmm2,[r8+24]; x1
	cvtsd2si r10,xmm2
	movsd xmm0,[r8+8]; y0
	cvtsd2si r9,xmm0
	movsd xmm0,[r8]; x0
	cvtsd2si r8,xmm0
	
	movsd [.x0],xmm0
	movsd [.z0],xmm1
	
	subsd xmm3,xmm1
	subsd xmm2,xmm0
	divsd xmm3,xmm2
	movsd [.depth_slope],xmm3

	cmp r8,r10
	je .vertical_line
	cmp r9,r11
	je .horizontal_line

	mov r12,r10
	sub r12,r8
	test r12,r12
	jns .abs_dx
	neg r12
.abs_dx:
	mov r13,r11
	sub r13,r9
	test r13,r13
	jns .abs_dy
	neg r13
.abs_dy:
	
	cmp r13,r12
	jge .plot_line_up

.plot_line_down:
	cmp r8,r10
	jle .plot_down	; plot line down forwards
	mov r12,r10
	mov r10,r8
	mov r8,r12
	mov r12,r11
	mov r11,r9
	mov r9,r12
	jmp .plot_down	; plot line down backwards

.plot_line_up:

	cmp r9,r11
	jle .plot_up	; plot line up forwards
	mov r12,r10
	mov r10,r8
	mov r8,r12
	mov r12,r11
	mov r11,r9
	mov r9,r12
	; plot line up backwards

.plot_up:
	mov r12,r10
	sub r12,r8	; dx = x1-x0
	mov r13,r11
	sub r13,r9	; dy = y1-y0
	mov rax,1	; x_step = 1
	test r12,r12
	jns .plot_abs_dx
	neg r12		; dx = -dx
	neg rax		; x_step = -1
.plot_abs_dx:
	mov rbx,r12
	shl rbx,1
	mov r14,rbx	; 2*dx
	sub rbx,r13	; D = 2dx-dy
	mov r15,r13
	shl r15,1
	sub r15,r14
	neg r15		; 2dx-2dy
	
.loop_up:
;	call set_pixel	; draw the current pixel
	call .process_pixel


	cmp r9,r11	; if we're done, return
	je .ret
	cmp rbx,0	; if D <= 0, don't adjust x
	jle .dont_adjust_x
	add r8,rax	; x += x_step
	add rbx,r15	; D += (2dx-2dy)
	inc r9		; y++
	jmp .loop_up
.dont_adjust_x:
	add rbx,r14	; D += 2dx
	inc r9		; y++
	jmp .loop_up

.plot_down:
	mov r12,r10
	sub r12,r8	; dx = x1-x0
	mov r13,r11
	sub r13,r9	; dy = y1-y0
	mov rax,1	; y_step = 1
	test r13,r13
	jns .plot_abs_dy
	neg r13		; dy = -dy
	neg rax		; y_step = -1
.plot_abs_dy:
	mov rbx,r13
	shl rbx,1
	mov r14,rbx	; 2*dy
	sub rbx,r12	; D = 2dy-dx
	mov r15,r12
	shl r15,1
	sub r15,r14
	neg r15		; 2dy-2dx
	
.loop_down:
	;call set_pixel	; draw the current pixel
	call .process_pixel
	
	cmp r8,r10	; if we're done, return
	je .ret
	cmp rbx,0	; if D <= 0, don't adjust y
	jle .dont_adjust_y
	add r9,rax	; y += y_step
	add rbx,r15	; D += (2dy-2dx)
	inc r8		; x++
	jmp .loop_down
.dont_adjust_y:
	add rbx,r14	; D += 2dy
	inc r8		; x++
	jmp .loop_down


.process_pixel:

	push rax
	push rbx
	push rbp

	; x in {r8}
	cvtsi2sd xmm0,r8
	subsd xmm0,[.x0]
	mulsd xmm0,[.depth_slope]
	addsd xmm0,[.z0]
	; depth of pixel of interest in {xmm0} (double precision)

	cvtsd2ss xmm0,xmm0 ; does work LOL

	mov rax,r8 ; x coord
	mov rbx,r9 ; y coord

	mov rbp,rbx
	imul rbp,rdx
	add rbp,rax
	shl rbp,2 ; {rbp} contains byte number for pixel of interest
	add rbp,r10	; {rbp} points to depth for pixel of interest
	movss xmm1,[rbp]

	comiss xmm0,xmm1
	jbe .too_deep_to_put_pixel
	
	; overwrite depth
	movss [rbp],xmm0

	; compute color at this point
	cmp r9,0 ; TODO should be a test instruction tbh, not cmp
	je .color_computed

	; todo some processing for gradient colors


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

	pop rbp
	pop rbx
	pop rax

	ret


.vertical_line:
	cmp r9,r11
	jl .loop_vertical
	mov rax,r9
	mov r9,r11
	mov r11,rax
.loop_vertical:
	call .process_pixel
	inc r9
	cmp r9,r11
	jle .loop_vertical

	jmp .ret

.horizontal_line:

	cmp r8,r10
	jl .loop_horizontal
	mov rax,r8
	mov r8,r10
	mov r10,rax
.loop_horizontal:
	call .process_pixel
	inc r8
	cmp r8,r10
	jle .loop_horizontal

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
	movdqu xmm11,[rsp+176]
	movdqu xmm12,[rsp+192]
	movdqu xmm13,[rsp+208]
	movdqu xmm14,[rsp+224]
	movdqu xmm15,[rsp+240]
	add rsp,256
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rsi
	pop rbp
	pop rbx
	pop rax
	
	ret

.vertices_copy:
	times 6 dq 0.0

.depth_slope: ; (z1-z0)/(x1-x0)
	dq 0.0
.x0:
	dq 0.0
.z0:
	dq 0.0


%if 0
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
%endif	

%endif
