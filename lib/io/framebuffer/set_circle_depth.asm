%ifndef SET_CIRCLE_DEPTH
%define SET_CIRCLE_DEPTH

; dependency
%include "lib/io/bitmap/set_pixel.asm"

set_circle_depth:
; void set_circle_depth(void* {rdi}, long {rsi}, int {edx}, int {ecx},
;		 double* {r8},single* {r9}, double {xmm0})
;	Plots circle of radius {xmm0} and center in 3 double-precision floats
;	starting at {r8} (projected x, projected y, projected depth)
;	in ARGB data array starting at {rdi} for an {edx}x{ecx} (WxH) image. 
;	{rsi} contains solid line color (32 bpp). Pointer to 
;	single-precision depth buffer at {r10} (4*{ecx}*{edx} bytes).

;	debug_regs print_int_d

	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push r14
	push r15
	push rbp

	sub rsp,48
	movdqu [rsp+0],xmm1
	movdqu [rsp+16],xmm2
	movdqu [rsp+32],xmm15


	mov [.depth_buffer_address],r9

	movsd xmm15,[r8+16]
	cvtsd2si r9,[r8+8]
	cvtsd2si r8,[r8+0]
	cvtsd2ss xmm15,xmm15
	cvtsd2si r10,xmm0


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
	; pixel @ (xc+dx,yc+dy)
	call .set_pixel_and_depth
	mov r8,r11
	sub r8,r14
	mov r9,r12
	add r9,r15
	; pixel @ (xc-dx,yc+dy)
	call .set_pixel_and_depth
	mov r8,r11
	add r8,r14
	mov r9,r12
	sub r9,r15
	; pixel @ (xc+dx,yc-dy)
	call .set_pixel_and_depth
	mov r8,r11
	sub r8,r14
	mov r9,r12
	sub r9,r15
	; pixel @ (xc-dx,yc-dy)
	call .set_pixel_and_depth
	mov r8,r11
	add r8,r15
	mov r9,r12
	add r9,r14
	; pixel @ (xc+dy,yc+dx)
	call .set_pixel_and_depth
	mov r8,r11
	sub r8,r15
	mov r9,r12
	add r9,r14
	; pixel @ (xc-dy,yc+dx)
	call .set_pixel_and_depth
	mov r8,r11
	add r8,r15
	mov r9,r12
	sub r9,r14
	; pixel @ (xc+dy,yc-dx)
	call .set_pixel_and_depth
	mov r8,r11
	sub r8,r15
	mov r9,r12
	sub r9,r14
	; pixel @ (xc-dy,yc-dx)
	call .set_pixel_and_depth

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
	movdqu xmm1,[rsp+0]
	movdqu xmm2,[rsp+16]
	movdqu xmm15,[rsp+32]
	add rsp,48

	pop rbp
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8

;	debug_regs print_int_d

;	debug_exit 5

	ret

.set_pixel_and_depth: ; needs pixel x,y at {r8,r9} and 4B-float depth @ {xmm15}

;	push rdx
	push rbp

	cmp r8d,0
	jle .skip_this_pixel
	cmp r8d,edx
	jge .skip_this_pixel
	cmp r9d,0
	jle .skip_this_pixel
	cmp r9d,ecx
	jge .skip_this_pixel


	mov rbp,r9
	imul rbp,rdx
	add rbp,r8
	shl rbp,2 ; {rbp} contains byte number for pixel of interest
	add rbp,[.depth_buffer_address]	; {rbp} points to depth for pixel of interest

	movss xmm1,[rbp]

	movss xmm2,xmm15

	subss xmm2,xmm1
	comiss xmm2,dword [.wireframe_depth_threshold]

	jb .too_deep

	call set_pixel
	movss [rbp],xmm15

.skip_this_pixel:
.too_deep:

	pop rbp
;	pop rdx
	ret

.depth_buffer_address:
	dq 0
.wireframe_depth_threshold:
	dd 0.1;	dd 1.0
%endif
