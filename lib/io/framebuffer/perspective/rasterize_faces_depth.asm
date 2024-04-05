%ifndef RASTERIZE_FACES_DEPTH
%define RASTERIZE_FACES_DEPTH

; dependencies
%include "lib/io/framebuffer/perspective/set_triangle_depth.asm"
%include "lib/math/vector/triangle_normal.asm"
%include "lib/math/vector/dot_product_3.asm"

rasterize_faces_depth:
; void rasterize_faces_depthbuffer(void* {rdi}, int {rsi}, int {edx}, 
;		int {ecx}, struct* {r8}, struct* {r9}, single* {r10}, bool {r11});
;	Rasterizes a set of faces described by the structure at {r9} from the
;	perspective described by the structure at {r8} to the {edx}x{ecx} (WxH)
;	image using the color value in the low 32 bits of {rsi} to the bitmap
;	starting at address {rdi}. The 32nd bit of {rsi} indicates the stacking
;	direction of the bitmap rows. If low bit of {r11} is high, colors stored
;	alongside vertex information in 32 byte chunks of (x,y,z,ARGB). If low 
;	bit of {r11} is low, solid face color stored in {rsi}.
;	Depthbuffer at {r10} (4*{ecx}*{edx} bytes).

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
.faces_structure:
	dq ; number of points (N)
	dq ; number of faces (M)
	dq .points ; starting address of point array (3N elements)
	dq .faces ; starting address of face array 
		;	(3M elements if no colors)
		;	(4M elements if colors)
%endif

	push rax
	push rcx
	push r10
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

	mov r15,[r9+8]	; number of faces in r15
	mov rax,[r9+24]
	;loop thru all faces

.loop_faces:

	push rdi
	push rsi
	push rdx
	mov rdi,SYS_STDOUT
	mov rsi,r15
	call print_int_d
	mov rsi,.grammar
	mov rdx,1
	call print_chars
	
	mov rsi,[rax]
	call print_int_d
	mov rsi,.grammar+1
	call print_chars
	mov rsi,[rax+8]
	call print_int_d
	mov rsi,.grammar+1
	call print_chars
	mov rsi,[rax+16]
	call print_int_d
	mov rsi,.grammar+1
	call print_chars

	mov rsi,.grammar
	call print_chars
	
	call print_buffer_flush
	pop rdx
	pop rsi
	pop rdi
;
	; first check if normal is pointing opposite the view direction
	push rdi
	push rsi
	push rdx
	push rcx
	; normal buffer
	mov rdi,.triangle_normal
	; vertex A	
	mov rsi,[rax]
	shl rsi,3
	imul rsi,rsi,3
	add rsi,[r9+16]
	; vertex B
	mov rdx,[rax+8]
	shl rdx,3
	imul rdx,rdx,3
	add rdx,[r9+16]
	; vertex C
	mov rcx,[rax+16]
	shl rcx,3
	imul rcx,rcx,3
	add rcx,[r9+16]
	call triangle_normal
	pop rcx
	pop rdx
	pop rsi
	pop rdi

	push rdi
	push rsi
	mov rdi,framebuffer_3d_render_depth_init.look_vector
	mov rsi,.triangle_normal
	call dot_product_3
	pop rsi
	pop rdi

	
	push rdi
	push rsi
	push rdx
	mov rdi,SYS_STDOUT
	mov rsi,.normal_completed
	mov rdx,10
	call print_chars
	call print_buffer_flush

	pop rdx
	pop rsi
	pop rdi


	pxor xmm1,xmm1
	comisd xmm0,xmm1
	jb .skip
	
	; rasterized pt x = (((Pt).(Ux)*f)/((Pt).Uz))*width/2+width/2
	; rasterized pt y = -(((Pt).(Uy)*f)/((Pt).Uz))*height/2+height/2
	; rasterized depth z = (Pt).(Uz)
	
	xor rcx,rcx
	mov rbp,.triangle_colors

.triangle_points_loop:

	; grab a point
	
	mov r14,[rax]
	shl r14,3
	imul r14,r14,3	; {r14} points to the x value of the first point
	add r14,[r9+16]

	movsd xmm3,[r14]	; Pt_x
	movsd xmm4,[r14+8]	; Pt_y
	movsd xmm5,[r14+16]	; Pt_z

	push rdi
	push rsi
	push rdx
	push rcx
	push r8
	push r9
	push r10
	mov rdi,SYS_STDOUT
	mov rsi,r14
	mov rdx,1
	mov rcx,3
	xor r8,r8
	mov r9,print_float
	mov r10,8
	call print_array_float
	call print_buffer_flush

	pop r10
	pop r9
	pop r8
	pop rcx
	pop rdx
	pop rsi
	pop rdi



	cmp r11,1
	jne .no_vtx_colors
	mov rbx,[r14+24]
	mov [rbp],rbx

.no_vtx_colors:

	; correct relative to lookFrom point
	subsd xmm3,[r8+0]
	subsd xmm4,[r8+8]
	subsd xmm5,[r8+16]

	movsd xmm0,[framebuffer_3d_render_depth_init.view_axes_old+48]
	movsd xmm1,[framebuffer_3d_render_depth_init.view_axes_old+56]
	movsd xmm2,[framebuffer_3d_render_depth_init.view_axes_old+64]

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

	divsd xmm0,xmm6
	divsd xmm7,xmm6

	;TODO parallelize
	addsd xmm0,[.one]
	mulsd xmm0,[framebuffer_3d_render_depth_init.half_width]
	addsd xmm7,[.one]
	mulsd xmm7,[framebuffer_3d_render_depth_init.half_height]
	
	movsd [rcx+.triangle_points+0],xmm0 ; projected x
	movsd [rcx+.triangle_points+8],xmm7 ; projected y
	movsd [rcx+.triangle_points+16],xmm6 ; projected depth z
			
	add rax,8
	add rbp,8
	add rcx,24
	cmp rcx,56
	jle .triangle_points_loop

	push rsi
	push rax
	push r8
	push r9

	mov r8,.triangle_points
	mov r9,r11
	; {r10} points to depth buffer
	cmp r11,1
	jne .set_triangle_depth
	mov rsi,.triangle_colors
.set_triangle_depth:

	push rdi
	push rsi
	push rdx
	push rcx
	push r8
	push r9
	push r10
	mov rdi,SYS_STDOUT
	mov rsi,.triangle_points
	mov rdx,3
	mov rcx,3
	xor r8,r8
	mov r9,print_float
	mov r10,8
	call print_array_float
	call print_buffer_flush

	pop r10
	pop r9
	pop r8
	pop rcx
	pop rdx
	pop rsi
	pop rdi



	call set_triangle_depth

	pop r9
	pop r8
	pop rax
	pop rsi

	add rax,8

.continue:
	dec r15
	jnz .loop_faces

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
	pop r10
	pop rcx
	pop rax

	ret

.skip:
	add rax,32
	jmp .continue

.one:
	dq 1.0
.neg:
	dq -1.0
align 16
	dq 0
.triangle_normal:
	times 3 dq 0.0
.triangle_points:	; store x and y and depth of 3 vertices as a float 
	times 9 dq 0.0
.triangle_colors:
	times 3 dq 0

.grammar:
	db `\n,`
.normal_completed:
	db `norm comp\n`
%endif
