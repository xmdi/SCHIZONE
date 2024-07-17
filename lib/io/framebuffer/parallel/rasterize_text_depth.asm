%ifndef RASTERIZE_TEXT_DEPTH
%define RASTERIZE_TEXT_DEPTH

; dependency
%include "lib/io/framebuffer/set_text_depth.asm"

rasterize_text_depth:
; void rasterize_text_depth(void* {rdi}, int {rsi}, int {edx}, 
;	int {ecx}, struct* {r8}, struct* {r9}, single* {r10});
;	Rasterizes the text described by the structure at {r9} from the
;	perspective described by the structure at {r8} to the {edx}x{ecx} (WxH)
;	image using the color value in the low 32 bits of {rsi} to the bitmap
;	starting at address {rdi}. The 32nd bit of {rsi} indicates the stacking
;	direction of the bitmap rows. Depth buffer at {r10}.

%if 0
.perspective_structure:
	dq 0.00 ; lookFrom_x	
	dq 0.00 ; lookFrom_y	
	dq 0.00 ; lookFrom_z	
	dq 0.00 ; lookAt_x	
	dq 0.00 ; lookAt_y	
	dq 0.00 ; lookAt_z	
	dq 0.00 ; upDir_x	
	dq 0.00 ; upDir_y	
	dq 0.00 ; upDir_z	
	dq 1.00	; zoom
%endif

%if 0
.text_structure:
	dq 0 ; address of 24-byte (x,y,z) position
	dq 0 ; address of null-terminated string
	dq 0 ; address of font definition
	dq 0 ; font-size (scaling of 8px)
%endif

	push rax
	push rbx
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push r14
	push r15
	push rbp
	sub rsp,192
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

	mov r14,[r9] 	; address of x,y,z for text

	;loop thru all points

	; rasterized pt x = ((Pt).(Ux)*zoom)*width/2+width/2
	; rasterized pt y = -((Pt).(Uy)*zoom)*height/2+height/2
	; rasterized depth z = (Pt).(Uz)

	movsd xmm3,[r14]	; Pt_x
	movsd xmm4,[r14+8]	; Pt_y
	movsd xmm5,[r14+16]	; Pt_z
	
	; correct relative to lookFrom point
	subsd xmm3,[r8+0]
	subsd xmm4,[r8+8]
	subsd xmm5,[r8+16]

	movsd xmm0,[framebuffer_3d_render_depth_init.view_axes+48]
	movsd xmm1,[framebuffer_3d_render_depth_init.view_axes+56]
	movsd xmm2,[framebuffer_3d_render_depth_init.view_axes+64]

	mulsd xmm0,xmm3
	mulsd xmm1,xmm4
	mulsd xmm2,xmm5
	
	addsd xmm0,xmm1
	addsd xmm0,xmm2		
	movsd xmm6,xmm0		; Pt.Uz in {xmm6}

	movsd xmm0,[framebuffer_3d_render_depth_init.Uxzoom+0]
	movsd xmm1,[framebuffer_3d_render_depth_init.Uxzoom+8]
	movsd xmm2,[framebuffer_3d_render_depth_init.Uxzoom+16]
	movsd xmm7,[framebuffer_3d_render_depth_init.Uyzoom+0]
	movsd xmm8,[framebuffer_3d_render_depth_init.Uyzoom+8]
	movsd xmm9,[framebuffer_3d_render_depth_init.Uyzoom+16]

	mulsd xmm0,xmm3
	mulsd xmm1,xmm4
	mulsd xmm2,xmm5	
	mulsd xmm7,xmm3
	mulsd xmm8,xmm4
	mulsd xmm9,xmm5
	
	addsd xmm0,xmm1
	addsd xmm0,xmm2		; Pt.Ux*f in {xmm0}	
	addsd xmm7,xmm8
	addsd xmm7,xmm9		; Pt.Uy*f in {xmm7}

	;TODO parallelize
	addsd xmm0,[.one]
	mulsd xmm0,[framebuffer_3d_render_depth_init.half_width]
	addsd xmm7,[.one]
	mulsd xmm7,[framebuffer_3d_render_depth_init.half_height]

	mov r8,r11
	mov r13,r12
	mov r12,[r9+16]	; font definition
	mov r11,[r9+8]	; text
	mov r10,[r9+24]	; font size
	mov r9,r13
	
	call set_text_depth

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
	add rsp,192
	pop rbp
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rbx
	pop rax

	ret

.x_offset:
	dq 0
.y_offset:
	dq 0
.z_offset:
	dq 0

.point_array:
	times 6 dq 0.0
.two:
	dq 2.0
.inv_sqrt3:
	dq 0x3FE279A74590331D
.half_sqrt3:
	dq 0x3FEBB67AE8584CAA
.one:
	dq 1.0
%endif
