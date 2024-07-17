%ifndef RASTERIZE_POINTCLOUD_DEPTH
%define RASTERIZE_POINTCLOUD_DEPTH

; dependencies
%include "lib/io/framebuffer/set_line_depth.asm"
%include "lib/io/framebuffer/set_circle_depth.asm"

rasterize_pointcloud_depth:
; void rasterize_pointcloud_depth(void* {rdi}, struct* {rsi}, int {edx}, 
;	int {ecx}, struct* {r8}, single* {r9});
;	Rasterizes a cloud of points described by the structure at {rsi} from
;	perspective described by the structure at {r8} to the {edx}x{ecx} (WxH)
;	image. Depthbuffer at {r9} (4*{ecx}*{edx} bytes).

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
.points_structure:
	dq 0 ; number of points (N)
	dq .points_x ; pointer to (x) point array (8N bytes)
	dq .points_y ; pointer to (y) point array (8N bytes)
	dq .points_z ; pointer to (z) point array (8N bytes)
	dq .marker_colors ; pointer (4N bytes)
	dq .marker_types ; pointer to render type (N bytes)
				; (1=O,2=X,3=[],4=tri)
	dq .marker_sizes ; pointer (N bytes)
	dw .stride_x ;
	dw .stride_y ;
	dw .stride_z ;
	dw .stride_colors ;
	dw .stride_types ;
	dw .stride_sizes ;
	dd 0 ; global marker color if NULL pointer set above
	db 0 ; point render type (1=O,2=X,3=[],4=tri) if NULL pointer set above
	db 0 ; characteristic size of each point if NULL pointer set above
%endif

	push rax
	push rbx
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

	mov r10,r9 	; save depth buffer to {r10}
	mov r14,rsi 	; pointcloud struct

	; default characteristics if not otherwise set by array
	mov esi, dword [r14+68]
	movzx r13, byte [r14+73]
	movzx rbp, byte [r14+72]

	cvtsi2sd xmm10,rbp 	; {xmm10} contains characteristic marker size
	movsd xmm11,xmm10 
	mulsd xmm11,[.two]

	mov r15,[r14+0]	; number of points in r15
	;mov rax,[r14+8] ; point to 0th point x coordinate
	;xor rax,rax ; point to 0th point x coordinate
	mov rbx,[r14+32] ; point to 0th point marker color
	mov r11,[r14+40] ; point to 0th point marker type
	mov r12,[r14+48] ; point to 0th point marker size

	xor rax,rax
	mov [.x_offset],rax
	mov [.y_offset],rax
	mov [.z_offset],rax

	;loop thru all points

.loop_points:

	; rasterized pt x = ((Pt).(Ux)*zoom)*width/2+width/2
	; rasterized pt y = -((Pt).(Uy)*zoom)*height/2+height/2
	; rasterized depth z = (Pt).(Uz)


	mov rax,[.x_offset]
	push rax
	add rax,[r14+8]
	movsd xmm3,[rax]	; Pt_x
	movzx rax, word [r14+56]
	add ax,8
	add rax,[rsp+0]
	add rsp,8
	mov [.x_offset],rax

	mov rax,[.y_offset]
	push rax
	add rax,[r14+16]
	movsd xmm4,[rax]	; Pt_y
	movzx rax, word [r14+58]
	add ax,8
	add rax,[rsp+0]
	add rsp,8
	mov [.y_offset],rax
	
	mov rax,[.z_offset]
	push rax
	add rax,[r14+24]
	movsd xmm5,[rax]	; Pt_z
	movzx rax, word [r14+60]
	add ax,8
	add rax,[rsp+0]
	add rsp,8
	mov [.z_offset],rax
	.a:
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
	
	; record Pt depth in array	
	movsd [.point_array+16],xmm6
	movsd [.point_array+40],xmm6

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

	; grab marker color
	cmp qword [r14+32],0
	je .color_set
	mov esi,dword [rbx]
	add rbx,4
	add rbx,[r14+62]
.color_set:
	; grab marker size
	cmp qword [r14+48],0
	je .size_set
	movzx r13,byte [r12]	
	
	cvtsi2sd xmm10,r13
	movsd xmm11,xmm10 
	mulsd xmm11,[.two]

	inc r12
	add r12,[r14+66]
.size_set:

	; handle different point types 
		
	; grab marker type
	cmp qword [r14+40],0
	je .type_set
	movzx rbp,byte [r11]
	inc r11
	add r11,[r14+64]
.type_set:

	cmp bpl,1
	je .circle_point
	cmp bpl,2
	je .x_point
	cmp bpl,3
	je .square_point
	cmp bpl,4
	je .triangle_point

	jmp .go_next_point ; invalid point type specified, skip

	; actually draw the point

.triangle_point:
	push r8
	push r9
	mov r8,.point_array
	mov r9,0x0100

	subsd xmm0,xmm10
	movsd xmm5,xmm10
	mulsd xmm5,[.inv_sqrt3]
	subsd xmm7,xmm5
	movsd [.point_array+0],xmm0
	movsd [.point_array+8],xmm7
	addsd xmm0,xmm11
	movsd [.point_array+24],xmm0
	movsd [.point_array+32],xmm7

	call set_line_depth ; bottom

	movsd xmm5,xmm11
	mulsd xmm5,[.half_sqrt3]

	subsd xmm0,xmm10
	addsd xmm7,xmm5
	movsd [.point_array+0],xmm0
	movsd [.point_array+8],xmm7
	
	call set_line_depth ; right

	subsd xmm0,xmm10
	subsd xmm7,xmm5
	movsd [.point_array+24],xmm0
	movsd [.point_array+32],xmm7
	
	call set_line_depth ; left
	
	pop r9
	pop r8
	jmp .go_next_point

.square_point:	
	push r8
	push r9
	mov r8,.point_array
	mov r9,0x0100

	subsd xmm0,xmm10	
	subsd xmm7,xmm10
	movsd [.point_array+0],xmm0
	movsd [.point_array+8],xmm7
	addsd xmm0,xmm11
	movsd [.point_array+24],xmm0
	movsd [.point_array+32],xmm7

	call set_line_depth ; bottom

	addsd xmm7,xmm11
	movsd [.point_array+0],xmm0
	movsd [.point_array+8],xmm7
	
	call set_line_depth ; right

	subsd xmm0,xmm11
	movsd [.point_array+24],xmm0
	movsd [.point_array+32],xmm7
	
	call set_line_depth ; top

	subsd xmm7,xmm11
	movsd [.point_array+0],xmm0
	movsd [.point_array+8],xmm7
	
	call set_line_depth ; left
	
	pop r9
	pop r8
	jmp .go_next_point

.x_point:
	
	push r8
	push r9
	mov r8,.point_array
	mov r9,0x0100

	subsd xmm0,xmm10	
	subsd xmm7,xmm10
	movsd [.point_array+0],xmm0
	movsd [.point_array+8],xmm7
	addsd xmm0,xmm11
	addsd xmm7,xmm11
	movsd [.point_array+24],xmm0
	movsd [.point_array+32],xmm7

	call set_line_depth ; slash 1

	subsd xmm0,xmm11
	movsd [.point_array+0],xmm0
	movsd [.point_array+8],xmm7
	
	addsd xmm0,xmm11
	subsd xmm7,xmm11
	movsd [.point_array+24],xmm0
	movsd [.point_array+32],xmm7
	
	call set_line_depth ; slash 2

	pop r9
	pop r8
	
	jmp .go_next_point

.circle_point:	

	push r8
	push r9
	mov r8,.point_array
	mov r9,r10

	movsd [.point_array+0],xmm0
	movsd [.point_array+8],xmm7

	movsd xmm0,xmm10
	call set_circle_depth ; slash 1

	pop r9
	pop r8

.go_next_point:

	dec r15
	jnz .loop_points

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
