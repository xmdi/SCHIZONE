%ifndef FRAMEBUFFER_3D_RENDER_DEPTH_LOOP
%define FRAMEBUFFER_3D_RENDER_DEPTH_LOOP

%include "lib/io/framebuffer/perspective/framebuffer_3d_render_depth_init.asm"
; void framebuffer_3d_render_depth_init(struct* {rdi}, struct* {rsi}, void* {rdx});

%include "lib/mem/memset.asm"
; void memset(void* {rdi}, char {sil}, ulong {rdx});

%include "lib/mem/memcopy.asm"
; void memcopy(long* {rdi}, long* {rsi}, ulong {rdx});

%include "lib/io/framebuffer/framebuffer_mouse_poll.asm"
; void framebuffer_mouse_poll(void);

%include "lib/io/framebuffer/framebuffer_flush.asm"
; void framebuffer_flush(void);

%include "lib/math/vector/distance_3.asm"
; double {xmm0} distance_3(double* {rdi}, double* {rsi});

%include "lib/math/expressions/trig/sine.asm"
; double {xmm0} sine(double {xmm0}, double {xmm1});

%include "lib/math/expressions/trig/cosine.asm"
; double {xmm0} cosine(double {xmm0}, double {xmm1});

framebuffer_3d_render_depth_loop:
; void framebuffer_3d_render_depth_loop(void);
;	Query mouse position and redraw the scene initialized by
;	framebuffer_3d_render_depth_init.

; No error handling; deal with it.

; NOTE: NEED TO RUN THIS AS SUDO

	push rdi
	push rsi
	push rdx
	push rcx
	push rax
	push r8
	push r9
	push r13
	push r14
	push r15
	sub rsp,112
	movdqu [rsp+0],xmm0
	movdqu [rsp+16],xmm1
	movdqu [rsp+32],xmm2
	movdqu [rsp+48],xmm7
	movdqu [rsp+64],xmm8
	movdqu [rsp+80],xmm14
	movdqu [rsp+96],xmm15

	; check mouse status	
	call framebuffer_mouse_poll
	xor r14,r14
	mov r14b,byte [framebuffer_mouse_init.mouse_state]

	cmp r14,0
	jg .drawing
	xor rax,rax
	mov [framebuffer_3d_render_depth_init.prev_mouse_x],rax
	mov [framebuffer_3d_render_depth_init.prev_mouse_y],rax
	jmp .no_drawing

.drawing:

	; if we just clicked for the first time, just save the current 
	;    mouse position and don't draw anything new
	mov r14,1
	mov byte [framebuffer_3d_render_depth_init.was_dragging],r14b
	
	mov r15,[framebuffer_3d_render_depth_init.perspective_structure_address]
	mov rax,[framebuffer_3d_render_depth_init.prev_mouse_x]
	add rax,[framebuffer_3d_render_depth_init.prev_mouse_y]
	cmp rax,0
	je .first_click

	; clear the background first
	mov rdi,[framebuffer_3d_render_depth_init.intermediate_buffer_address]
	xor sil,sil
	mov rdx,[framebuffer_init.framebuffer_size]
	call memset

	movsxd r8,[framebuffer_mouse_init.mouse_x]
	movsxd r9,[framebuffer_mouse_init.mouse_y]

	cmp byte [framebuffer_mouse_init.mouse_state],1
	je .left_click
	cmp byte [framebuffer_mouse_init.mouse_state],2
	je .right_click
	cmp byte [framebuffer_mouse_init.mouse_state],4
	je .middle_click

.left_click:
	; (rotating)
	; rotate the look_From point about the look_At point

	mov rax,r8
	sub rax,[framebuffer_3d_render_depth_init.prev_mouse_x]
	cvtsi2sd xmm0,rax
	mulsd xmm0,[framebuffer_3d_render_depth_init.rotate_scale]
	movsd [framebuffer_3d_render_depth_init.yaw],xmm0	
	
	mov rax,r9
	sub rax,[framebuffer_3d_render_depth_init.prev_mouse_y]
	cvtsi2sd xmm0,rax
	mulsd xmm0,[framebuffer_3d_render_depth_init.rotate_scale]
	movsd [framebuffer_3d_render_depth_init.pitch],xmm0

	movsd xmm1,[framebuffer_3d_render_depth_init.tolerance]
	call cosine
	movsd [framebuffer_3d_render_depth_init.cos_pitch],xmm0

	movsd xmm0,[framebuffer_3d_render_depth_init.pitch]
	call sine
	movsd [framebuffer_3d_render_depth_init.sin_pitch],xmm0

	movsd xmm0,[framebuffer_3d_render_depth_init.yaw]
	call cosine
	movsd [framebuffer_3d_render_depth_init.cos_yaw],xmm0

	movsd xmm0,[framebuffer_3d_render_depth_init.yaw]
	call sine
	movsd [framebuffer_3d_render_depth_init.sin_yaw],xmm0

	; grab the old view system
	mov rdi,framebuffer_3d_render_depth_init.view_axes
	mov rsi,framebuffer_3d_render_depth_init.view_axes_old
	mov rdx,72
	call memcopy

	;.u1'[0]
	movsd xmm15,[framebuffer_3d_render_depth_init.view_axes+8]
	mulsd xmm15,[framebuffer_3d_render_depth_init.view_axes+40]
	movsd xmm14,[framebuffer_3d_render_depth_init.view_axes+16]
	mulsd xmm14,[framebuffer_3d_render_depth_init.view_axes+32]
	subsd xmm15,xmm14
	mulsd xmm15,[framebuffer_3d_render_depth_init.sin_yaw]
	movsd xmm0,[framebuffer_3d_render_depth_init.view_axes+0]
	mulsd xmm0,[framebuffer_3d_render_depth_init.cos_yaw]
	addsd xmm0,xmm15

	;.u1'[1]
	movsd xmm15,[framebuffer_3d_render_depth_init.view_axes+16]
	mulsd xmm15,[framebuffer_3d_render_depth_init.view_axes+24]
	movsd xmm14,[framebuffer_3d_render_depth_init.view_axes+0]
	mulsd xmm14,[framebuffer_3d_render_depth_init.view_axes+40]
	subsd xmm15,xmm14
	mulsd xmm15,[framebuffer_3d_render_depth_init.sin_yaw]
	movsd xmm1,[framebuffer_3d_render_depth_init.view_axes+8]
	mulsd xmm1,[framebuffer_3d_render_depth_init.cos_yaw]
	addsd xmm1,xmm15

	;.u1'[2]
	movsd xmm15,[framebuffer_3d_render_depth_init.view_axes+0]
	mulsd xmm15,[framebuffer_3d_render_depth_init.view_axes+32]
	movsd xmm14,[framebuffer_3d_render_depth_init.view_axes+8]
	mulsd xmm14,[framebuffer_3d_render_depth_init.view_axes+24]
	subsd xmm15,xmm14
	mulsd xmm15,[framebuffer_3d_render_depth_init.sin_yaw]
	movsd xmm2,[framebuffer_3d_render_depth_init.view_axes+16]
	mulsd xmm2,[framebuffer_3d_render_depth_init.cos_yaw]
	addsd xmm2,xmm15

	; move rotated .u1' into the view_axes
	movsd [framebuffer_3d_render_depth_init.view_axes+0],xmm0
	movsd [framebuffer_3d_render_depth_init.view_axes+8],xmm1
	movsd [framebuffer_3d_render_depth_init.view_axes+16],xmm2

	;.u2'[0]
	movsd xmm15,[framebuffer_3d_render_depth_init.view_axes+32]
	mulsd xmm15,[framebuffer_3d_render_depth_init.view_axes+16]
	movsd xmm14,[framebuffer_3d_render_depth_init.view_axes+40]
	mulsd xmm14,[framebuffer_3d_render_depth_init.view_axes+8]
	subsd xmm15,xmm14
	mulsd xmm15,[framebuffer_3d_render_depth_init.sin_pitch]
	movsd xmm0,[framebuffer_3d_render_depth_init.view_axes+24]
	mulsd xmm0,[framebuffer_3d_render_depth_init.cos_pitch]
	addsd xmm0,xmm15

	;.u2'[1]
	movsd xmm15,[framebuffer_3d_render_depth_init.view_axes+40]
	mulsd xmm15,[framebuffer_3d_render_depth_init.view_axes+0]
	movsd xmm14,[framebuffer_3d_render_depth_init.view_axes+24]
	mulsd xmm14,[framebuffer_3d_render_depth_init.view_axes+16]
	subsd xmm15,xmm14
	mulsd xmm15,[framebuffer_3d_render_depth_init.sin_pitch]
	movsd xmm1,[framebuffer_3d_render_depth_init.view_axes+32]
	mulsd xmm1,[framebuffer_3d_render_depth_init.cos_pitch]
	addsd xmm1,xmm15

	;.u2'[2]
	movsd xmm15,[framebuffer_3d_render_depth_init.view_axes+24]
	mulsd xmm15,[framebuffer_3d_render_depth_init.view_axes+8]
	movsd xmm14,[framebuffer_3d_render_depth_init.view_axes+32]
	mulsd xmm14,[framebuffer_3d_render_depth_init.view_axes+0]
	subsd xmm15,xmm14
	mulsd xmm15,[framebuffer_3d_render_depth_init.sin_pitch]
	movsd xmm2,[framebuffer_3d_render_depth_init.view_axes+40]
	mulsd xmm2,[framebuffer_3d_render_depth_init.cos_pitch]
	addsd xmm2,xmm15

	; move rotated .u2' into the view_axes
	movsd [framebuffer_3d_render_depth_init.view_axes+24],xmm0
	movsd [framebuffer_3d_render_depth_init.view_axes+32],xmm1
	movsd [framebuffer_3d_render_depth_init.view_axes+40],xmm2

	;.u3'[0]
	movsd xmm15,[framebuffer_3d_render_depth_init.view_axes+8]
	mulsd xmm15,[framebuffer_3d_render_depth_init.view_axes+40]
	movsd xmm14,[framebuffer_3d_render_depth_init.view_axes+16]
	mulsd xmm14,[framebuffer_3d_render_depth_init.view_axes+32]
	subsd xmm15,xmm14
	movsd [framebuffer_3d_render_depth_init.view_axes+48],xmm15

	;.u3'[1]
	movsd xmm15,[framebuffer_3d_render_depth_init.view_axes+16]
	mulsd xmm15,[framebuffer_3d_render_depth_init.view_axes+24]
	movsd xmm14,[framebuffer_3d_render_depth_init.view_axes+0]
	mulsd xmm14,[framebuffer_3d_render_depth_init.view_axes+40]
	subsd xmm15,xmm14
	movsd [framebuffer_3d_render_depth_init.view_axes+56],xmm15

	;.u3'[2]
	movsd xmm15,[framebuffer_3d_render_depth_init.view_axes+0]
	mulsd xmm15,[framebuffer_3d_render_depth_init.view_axes+32]
	movsd xmm14,[framebuffer_3d_render_depth_init.view_axes+8]
	mulsd xmm14,[framebuffer_3d_render_depth_init.view_axes+24]
	subsd xmm15,xmm14
	movsd [framebuffer_3d_render_depth_init.view_axes+64],xmm15

	; copy up-direction into structure
	mov rdi,r15
	add rdi,48
	mov rsi,framebuffer_3d_render_depth_init.view_axes+24
	mov rdx,24
	call memcopy

	; copy looking direction into structure
	movsd xmm15,[framebuffer_3d_render_depth_init.view_axes+48]
	mulsd xmm15,[framebuffer_3d_render_depth_init.look_distance]
	addsd xmm15,[r15+24]
	movsd [r15+0],xmm15
	movsd xmm15,[framebuffer_3d_render_depth_init.view_axes+56]
	mulsd xmm15,[framebuffer_3d_render_depth_init.look_distance]
	addsd xmm15,[r15+32]
	movsd [r15+8],xmm15
	movsd xmm15,[framebuffer_3d_render_depth_init.view_axes+64]
	mulsd xmm15,[framebuffer_3d_render_depth_init.look_distance]
	addsd xmm15,[r15+40]
	movsd [r15+16],xmm15

	jmp .draw_wires

.right_click:
	; (panning)
	; translate both the lookat and lookfrom point along u1 and u2

	mov rax,r8
	sub rax,[framebuffer_3d_render_depth_init.prev_mouse_x]
	cvtsi2sd xmm0,rax
	mulsd xmm0,[framebuffer_3d_render_depth_init.pan_scale_x]
	movsd xmm7,xmm0	; rightward shifting
	
	mov rax,r9
	sub rax,[framebuffer_3d_render_depth_init.prev_mouse_y]
	cvtsi2sd xmm0,rax
	mulsd xmm0,[framebuffer_3d_render_depth_init.pan_scale_y]
	movsd xmm8,xmm0 ; upward shifting
	
	; adjust vector x-coords
	movsd xmm0,[framebuffer_3d_render_depth_init.view_axes_old+0]
	mulsd xmm0,xmm7
	movsd xmm1,[framebuffer_3d_render_depth_init.view_axes_old+24]
	mulsd xmm1,xmm8
	subsd xmm0,xmm1
	movsd xmm1,[framebuffer_3d_render_depth_init.perspective_old+0]
	subsd xmm1,xmm0
	movsd [r15+0],xmm1	
	movsd xmm1,[framebuffer_3d_render_depth_init.perspective_old+24]
	subsd xmm1,xmm0
	movsd [r15+24],xmm1	
	
	; adjust vector y-coords
	movsd xmm0,[framebuffer_3d_render_depth_init.view_axes_old+8]
	mulsd xmm0,xmm7
	movsd xmm1,[framebuffer_3d_render_depth_init.view_axes_old+32]
	mulsd xmm1,xmm8
	subsd xmm0,xmm1
	movsd xmm1,[framebuffer_3d_render_depth_init.perspective_old+8]
	subsd xmm1,xmm0
	movsd [r15+8],xmm1	
	movsd xmm1,[framebuffer_3d_render_depth_init.perspective_old+32]
	subsd xmm1,xmm0
	movsd [r15+32],xmm1	

	; adjust vector z-coords
	movsd xmm0,[framebuffer_3d_render_depth_init.view_axes_old+16]
	mulsd xmm0,xmm7
	movsd xmm1,[framebuffer_3d_render_depth_init.view_axes_old+40]
	mulsd xmm1,xmm8
	subsd xmm0,xmm1
	movsd xmm1,[framebuffer_3d_render_depth_init.perspective_old+16]
	subsd xmm1,xmm0
	movsd [r15+16],xmm1	
	movsd xmm1,[framebuffer_3d_render_depth_init.perspective_old+40]
	subsd xmm1,xmm0
	movsd [r15+40],xmm1	

	jmp .draw_wires

.middle_click:
	; (zooming)
	; adjust the zoom factor
	mov rax,r9
	sub rax,[framebuffer_3d_render_depth_init.prev_mouse_y]
	cvtsi2sd xmm0,rax
	mulsd xmm0,[framebuffer_3d_render_depth_init.zoom_scale] ; zooming
	movsd xmm1,[framebuffer_3d_render_depth_init.zoom_old]
	subsd xmm1,xmm0
	movsd [r15+72],xmm1	

.draw_wires:

	; reset depth buffer to start at -Inf
	push rdi
	push rcx
	push rbx

	mov rcx,[framebuffer_init.framebuffer_size]
	shr rcx,2
	mov rdi,[framebuffer_3d_render_depth_init.depth_buffer_address]
	mov ebx,[framebuffer_3d_render_depth_init.Inf]

.depth_buffer_init:
	mov [rdi],ebx	
	add rdi,4
	dec rcx
	jnz .depth_buffer_init

	pop rbx
	pop rcx
	pop rdi

	; Uy = (upDir)
	; Ux = (upDir)x(lookFrom-lookAt)

	; rasterized pt x = (((Pt).(Ux)*f)/((Pt).Uz))*width/2+width/2
	; rasterized pt y = -(((Pt).(Uy)*f)/((Pt).Uz))*height/2+height/2

	; precompute Ux*zoom 

	cvtsi2sd xmm0,[framebuffer_init.framebuffer_width]
	cvtsi2sd xmm2,[framebuffer_init.framebuffer_height]
	divsd xmm2,xmm0

	movsd xmm0,[framebuffer_3d_render_depth_init.view_axes+0]
	mulsd xmm0,[r15+72]
	mulsd xmm0,xmm2
	movsd [framebuffer_3d_render_depth_init.Uxzoom+0],xmm0
	movsd xmm0,[framebuffer_3d_render_depth_init.view_axes+8]
	mulsd xmm0,[r15+72]
	mulsd xmm0,xmm2
	movsd [framebuffer_3d_render_depth_init.Uxzoom+8],xmm0
	movsd xmm0,[framebuffer_3d_render_depth_init.view_axes+16]
	mulsd xmm0,[r15+72]
	mulsd xmm0,xmm2
	movsd [framebuffer_3d_render_depth_init.Uxzoom+16],xmm0

	; precompute Uy*zoom
	movsd xmm0,[framebuffer_3d_render_depth_init.view_axes+24]
	mulsd xmm0,[r15+72]
	movsd [framebuffer_3d_render_depth_init.Uyzoom+0],xmm0
	movsd xmm0,[framebuffer_3d_render_depth_init.view_axes+32]
	mulsd xmm0,[r15+72]
	movsd [framebuffer_3d_render_depth_init.Uyzoom+8],xmm0
	movsd xmm0,[framebuffer_3d_render_depth_init.view_axes+40]
	mulsd xmm0,[r15+72]
	movsd [framebuffer_3d_render_depth_init.Uyzoom+16],xmm0

	; process objects
	push rdi
	mov rdi,[framebuffer_3d_render_depth_init.intermediate_buffer_address]
	call framebuffer_3d_render_depth_switch
	pop rdi

	jmp .was_not_dragging

.first_click:
	
	mov rdi,framebuffer_3d_render_depth_init.view_axes
	mov rsi,framebuffer_3d_render_depth_init.view_axes_old
	mov rdx,72
	call memcopy

	mov rdi,framebuffer_3d_render_depth_init.perspective_old
	mov rsi,r15
	mov rdx,48
	call memcopy

	mov rdi,framebuffer_3d_render_depth_init.zoom_old
	mov rsi,r15
	add rsi,72
	mov rdx,8
	call memcopy

	mov eax,[framebuffer_mouse_init.mouse_x]
	mov [framebuffer_3d_render_depth_init.prev_mouse_x],rax
	mov eax,[framebuffer_mouse_init.mouse_y]
	mov [framebuffer_3d_render_depth_init.prev_mouse_y],rax

.no_drawing:
	cmp byte [framebuffer_3d_render_depth_init.was_dragging],1
	jne .was_not_dragging
.just_finished_dragging:
	mov rdi,framebuffer_3d_render_depth_init.view_axes_old
	mov rsi,framebuffer_3d_render_depth_init.view_axes
	mov rdx,72
	call memcopy
	xor r14,r14	
	mov byte [framebuffer_3d_render_depth_init.was_dragging],r14b

.was_not_dragging:
;;; combine layers to plot the cursor to the screen
	
	; first copy intermediate buffer to framebuffer
	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,[framebuffer_3d_render_depth_init.intermediate_buffer_address]
	mov rdx,[framebuffer_init.framebuffer_size]
	call memcopy

	; then draw the cursor as foreground onto the framebuffer
	mov rdi,[framebuffer_init.framebuffer_address]
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	mov r8d,[framebuffer_mouse_init.mouse_x]
	mov r9d,[framebuffer_mouse_init.mouse_y]
	call [framebuffer_3d_render_depth_init.cursor_function_address]

	; flush output to the screen
	call framebuffer_flush
	
	movdqu xmm0,[rsp+0]
	movdqu xmm1,[rsp+16]
	movdqu xmm2,[rsp+32]
	movdqu xmm7,[rsp+48]
	movdqu xmm8,[rsp+64]
	movdqu xmm14,[rsp+80]
	movdqu xmm15,[rsp+96]
	add rsp,112
	pop r15
	pop r14
	pop r13
	pop r9
	pop r8
	pop rax
	pop rcx
	pop rdx
	pop rsi
	pop rdi
	
	ret

%endif	
