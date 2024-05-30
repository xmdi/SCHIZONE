%ifndef RASTERIZE_EDGES_DEPTH
%define RASTERIZE_EDGES_DEPTH

; dependencies
%include "lib/io/framebuffer/set_line_depth.asm"

rasterize_edges_depth:
; void rasterize_edges_depth(void* {rdi}, int {rsi}, int {edx}, 
;	int {ecx}, struct* {r8}, struct* {r9}, single* {r10}, long {r11});
;	Rasterizes a set of edges described by the structure at {r9} from the
;	perspective described by the structure at {r8} to the {edx}x{ecx} (WxH)
;	image using the color value in the low 32 bits of {rsi} to the bitmap
;	starting at address {rdi}. The 32nd bit of {rsi} indicates the stacking
;	direction of the bitmap rows. If {r11}=2, colors stored alongside vertex 
;	information in 32-byte chunks of (x,y,z,ARGB). If {r11}=1, colors stored
;	alongside edge information in 32-byte chunks (v0,v1,v2,ARGB). If {r11}=0,
;	solid edge color stored in {rsi}. Depthbuffer at {r10} 
;	(4*{ecx}*{edx} bytes).

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
.edges_structure:
	dq ; number of points (N)
	dq ; number of edges (M)
	dq .points ; starting address of point array (2N elements)
	dq .edges ; starting address of edge array 
		;	(2M elements if no colors)
		;	(3M elements if colors)
%endif

	push rax
	push rbx
	push rcx
	push r13
	push r14
	push r15
	sub rsp,160
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

	mov r15,[r9+8]	; number of edges in r15
	mov rax,[r9+24]
	;loop thru all edges

.loop_edges:

	; rasterized pt x = ((Pt).(Ux)*zoom)*width/2+width/2
	; rasterized pt y = -((Pt).(Uy)*zoom)*height/2+height/2
	; rasterized depth z = (Pt).(Uz)

	xor r13,r13
	mov rbp,.line_colors

.line_points_loop:

	; grab a point
	
	mov r14,[rax]
	shl r14,3
	cmp r11,2
	jne .no_encoded_color
	imul r14,r14,4	; {r14} points to the x value of the first point
	jmp .color_encoding
.no_encoded_color:
	imul r14,r14,3	; {r14} points to the x value of the first point
.color_encoding:
	add r14,[r9+16]

	movsd xmm3,[r14]	; Pt_x
	movsd xmm4,[r14+8]	; Pt_y
	movsd xmm5,[r14+16]	; Pt_z

	cmp r11,2
	jne .no_vtx_colors

	mov rbx,[r14+24]
	mov [rbp],rbx
	add rbp,8

.no_vtx_colors:

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

	movsd [r13+.line_points+0],xmm0 ; projected x
	movsd [r13+.line_points+8],xmm7 ; projected y
	movsd [r13+.line_points+16],xmm6 ; projected depth z
			
	add rax,8
	add r13,24
	cmp r13,24
	jle .line_points_loop

	push rsi
	push rax
	push r8
	push r9

	; {r10} points to depth buffer
	mov r8,.line_points
	
	cmp r11,2
	je .colors_interpolated_from_vertices
	cmp r11,1
	je .colors_set_per_edge
	cmp r11,0
	je .solid_color_override

.colors_interpolated_from_vertices:
	mov r9,1
	mov rsi,.line_colors
	jmp .set_line_depth
.colors_set_per_edge:
	mov rsi,[rax]
.solid_color_override:
	; color in {rsi} from function call
	xor r9,r9

.set_line_depth:

	call set_line_depth
	
	pop r9
	pop r8
	pop rax
	pop rsi

	add rax,8

.continue:
	dec r15
	jnz .loop_edges
.jmp_out:
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
	add rsp,160
	pop r15
	pop r14
	pop r13
	pop rcx
	pop rbx
	pop rax
	ret

.skip:
	add rax,32
	jmp .continue

.one:
	dq 1.0
.line_points:	; store x and y and depth of 2 vertices as a float 
	times 6 dq 0.0
.line_colors:
	times 3 dq 0
.working:
	times 3 dq 0
%endif
