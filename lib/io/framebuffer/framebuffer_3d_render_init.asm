%ifndef FRAMEBUFFER_3D_RENDER_INIT
%define FRAMEBUFFER_3D_RENDER_INIT

%include "lib/mem/heap_init.asm"
; void heap_init(void);

%include "lib/mem/memcopy.asm"
; void memcopy(long* {rdi}, long* {rsi}, ulong {rdx});

%include "lib/io/framebuffer/framebuffer_clear.asm"
; void framebuffer_clear(uint {rdi});

%include "lib/io/framebuffer/framebuffer_flush.asm"
; void framebuffer_flush(void);

%include "lib/io/framebuffer/centroid_sort.asm"
; void centroid_sort(struct* {rdi}, struct* {rsi});

%include "lib/io/bitmap/rasterize_faces.asm"
; void rasterize_faces(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 struct* {r8}, struct* {r9});

%include "lib/io/bitmap/rasterize_text.asm"
; void rasterize_text(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 struct* {r8}, struct* {r9});

%include "lib/io/bitmap/rasterize_edges.asm"
; void rasterize_edges(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 struct* {r8}, struct* {r9});

%include "lib/io/bitmap/rasterize_pointcloud.asm"
; void rasterize_pointcloud(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 struct* {r8}, struct* {r9});

%include "lib/math/vector/normalize_3.asm"
; void normalize_3(double* {rdi});

%include "lib/math/vector/perpendicularize_3.asm"
; void perpendicularize_3(double* {rdi}, double* {rsi});

%include "lib/math/vector/cross_product_3.asm"
; void cross_product_3(double* {rdi}, double* {rsi}, double* {rdx});

framebuffer_3d_render_init:
; void framebuffer_3d_render_init(struct* {rdi}, struct* {rsi}, void* {rdx});
;	Initializes a 3D rendering setup with a perspective structure at
;	{rdi}, geometry linked list at {rsi}, and a cursor plotting function
;	at {rdx}.

; No error handling; deal with it.

; NOTE: NEED TO RUN THIS AS SUDO

%if 0
.geometry_linked_list:
	dq 0 ; next geometry in linked list
	dq 0 ; address of point/edge/face structure
	dq 0 ; color (0xARGB)
	db 0 ; type of structure to render
%endif

	push rdi
	push rsi
	push rdx
	push rcx
	push rax
	push rbx
	push r8
	push r9	
	push r14
	push r15
	sub rsp,16
	movdqu [rsp+0],xmm15
	
	mov [.perspective_structure_address],rdi
	mov [.geometry_linked_list_address],rsi
	mov [.cursor_function_address],rdx
	mov r15,rdi

	call heap_init

	call framebuffer_init
	
	call framebuffer_mouse_init

	mov rdi,[framebuffer_init.framebuffer_size]
	call heap_alloc
	mov rbx,rax	; buffer to combine multiple layers
	mov [.intermediate_buffer_address],rbx

	; clear the screen to start
	mov rdi,0xFF000000
	call framebuffer_clear

	; compute the view axes Z-direction
	movsd xmm15,[r15]
	subsd xmm15,[r15+24]
	movsd [.view_axes_old+48],xmm15
	movsd xmm15,[r15+8]
	subsd xmm15,[r15+32]
	movsd [.view_axes_old+56],xmm15
	movsd xmm15,[r15+16]
	subsd xmm15,[r15+40]
	movsd [.view_axes_old+64],xmm15
	
	; perpendicularize the Up-direction vector
	mov rdi,r15
	add rdi,48
	mov rsi,.view_axes_old+48
	call perpendicularize_3
	
	; compute rightward direction
	mov rdi,.view_axes_old+0
	mov rsi,r15
	add rsi,48
	mov rdx,.view_axes_old+48
	call cross_product_3	

	mov rdi,.view_axes_old+24
	mov rsi,r15
	add rsi,48
	mov rdx,24
	call memcopy

	movsd xmm15,[r15]
	subsd xmm15,[r15+24]
	movsd [.view_axes_old+48],xmm15
	movsd xmm15,[r15+8]
	subsd xmm15,[r15+32]
	movsd [.view_axes_old+56],xmm15
	movsd xmm15,[r15+16]
	subsd xmm15,[r15+40]
	movsd [.view_axes_old+64],xmm15
	
	; normalize the axes
	mov rdi,.view_axes_old+0
	call normalize_3
	mov rdi,.view_axes_old+24
	call normalize_3
	mov rdi,.view_axes_old+48
	call normalize_3

	; copy up-direction into structure
	mov rdi,r15
	add rdi,48
	mov rsi,.view_axes_old+24
	mov rdx,24
	call memcopy

	mov r14,[.geometry_linked_list_address]

.loop:
	; need to put some logic hear to accommodate things that aren't wireframes

	cmp byte [r14+24],0b00000001
	je .is_pointcloud

	cmp byte [r14+24],0b00000010
	je .is_wireframe

	cmp byte [r14+24],0b00001000
	je .is_text

	cmp byte [r14+24],0b00000100
	je .is_face

	cmp byte [r14+24],0b00000101
	je .is_shell_list

	jmp .geometry_type_unsupported

.is_pointcloud:
	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,[r14+16]
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	mov r8,[framebuffer_3d_render_init.perspective_structure_address]
	mov r9,[r14+8]
	call rasterize_pointcloud	

	jmp .geometry_type_unsupported

.is_wireframe:
	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,[r14+16]
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	mov r8,[framebuffer_3d_render_init.perspective_structure_address]
	mov r9,[r14+8]
	call rasterize_edges	

	jmp .geometry_type_unsupported

.is_face:
	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,[r14+16]
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	mov r8,[framebuffer_3d_render_init.perspective_structure_address]
	mov r9,[r14+8]
	call rasterize_faces

	jmp .geometry_type_unsupported

.is_shell_list:

	mov rdi,[r14+8]
	mov rsi,[framebuffer_3d_render_init.perspective_structure_address]
	call centroid_sort ; sort all shell bodies by distance from viewer

	mov rcx,[r14+8]
	mov rdx,rcx
	add rdx,8
	mov rcx,[rcx]
	cmp rcx,0	
	jbe .geometry_type_unsupported

.shell_body_loop:

	push rdx
	push rcx
	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,[r14+16]
	mov r9,[rdx]
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	mov r8,[framebuffer_3d_render_init.perspective_structure_address]
	call rasterize_faces
	pop rcx
	pop rdx

	add rdx,32
	dec rcx
	jnz .shell_body_loop

	jmp .geometry_type_unsupported

.is_text:
	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,[r14+16]
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	mov r8,[framebuffer_3d_render_init.perspective_structure_address]
	mov r9,[r14+8]
	call rasterize_text

.geometry_type_unsupported:

	cmp qword [r14],0
	je .done

	mov r14,[r14]
	jmp .loop

.done:

	call framebuffer_flush
	
	; copy this to the intermediate buffer to start
	mov rdi,rbx
	mov rsi,[framebuffer_init.framebuffer_address]
	mov rdx,[framebuffer_init.framebuffer_size]
	call memcopy
	
	movdqu xmm15,[rsp+0]
	add rsp,16
	pop r15
	pop r14
	pop r9
	pop r8
	pop rbx
	pop rax
	pop rcx
	pop rdx
	pop rsi
	pop rdi

	ret

.perspective_structure_address:
	dq 0
.geometry_linked_list_address:
	dq 0
.cursor_function_address:
	dq 0
.yaw:
	dq 0.0
.pitch:
	dq 0.0
.sin_yaw:
	dq 0.0
.sin_pitch:
	dq 0.0
.cos_yaw:
	dq 0.0
.cos_pitch:
	dq 0.0
.tolerance:
	dq 0.0001
.rotate_scale:
	dq 0.005
.pan_scale_x:
	dq 0.013
.pan_scale_y:
	dq 0.0062
.zoom_scale:
	dq 0.001
.prev_mouse_x:
	dq 0
.prev_mouse_y:
	dq 0
.mouse_clicked:
	db 0
.intermediate_buffer_address:
	dq 0
.view_axes:
	times 3 dq 0.0
	times 3 dq 0.0
	times 3 dq 0.0
.view_axes_old:
	times 3 dq 0.0
	times 3 dq 0.0
	times 3 dq 0.0
.perspective_old:
	times 10 dq 0.0
.zoom_old:
	dq 0.0
.was_dragging:
	db 0

%endif	
