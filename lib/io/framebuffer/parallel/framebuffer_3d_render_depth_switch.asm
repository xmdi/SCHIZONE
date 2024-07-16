%ifndef FRAMEBUFFER_3D_RENDER_DEPTH_SWITCH
%define FRAMEBUFFER_3D_RENDER_DEPTH_SWITCH

%include "lib/io/framebuffer/parallel/framebuffer_3d_render_depth_init.asm"
%include "lib/io/framebuffer/parallel/rasterize_faces_depth.asm"
%include "lib/io/framebuffer/parallel/rasterize_text_depth.asm"
%include "lib/io/framebuffer/parallel/rasterize_edges_depth.asm"
%include "lib/io/framebuffer/parallel/rasterize_pointcloud_depth.asm"

framebuffer_3d_render_depth_switch:
; void framebuffer_3d_render_depth_switch(void* {rdi});
;	Processes objects for the 3D rendering setup with  
;	depth located at {rdi}.

; No error handling; deal with it.

; NOTE: NEED TO RUN THIS AS SUDO

	push rsi
	push rdx
	push rcx
	push r8
	push r9	
	push r10
	push r11
	push r14

	mov r14,[framebuffer_3d_render_depth_init.geometry_linked_list_address]
	
;	mov rdi,[framebuffer_init.framebuffer_address]
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	mov r8,[framebuffer_3d_render_depth_init.perspective_structure_address]
	mov r10,[framebuffer_3d_render_depth_init.depth_buffer_address]

.loop:
	; need to put some logic hear to accommodate things that aren't wireframes

	mov rsi,[r14+16]
	mov r9,[r14+8]

	cmp byte [r14+24],0b00000001
	je .is_pointcloud

	cmp byte [r14+24],0b00001000
	je .is_wireframe_from_solid_color

	cmp byte [r14+24],0b00001001
	je .is_wireframe_from_edge_color

	cmp byte [r14+24],0b00001010
	je .is_wireframe_interpolated_color

	cmp byte [r14+24],0b00000100
	je .is_face_from_solid_color

	cmp byte [r14+24],0b00000101
	je .is_face_from_face_color

	cmp byte [r14+24],0b00000110
	je .is_face_interpolated_color

	cmp byte [r14+24],0b00000010
	je .is_text

	jmp .geometry_type_unsupported

.is_pointcloud:

	mov rsi,r9
	mov r9,[framebuffer_3d_render_depth_init.depth_buffer_address]

	call rasterize_pointcloud_depth

	jmp .geometry_type_unsupported

.is_wireframe_from_solid_color:
	xor r11,r11
	call rasterize_edges_depth

	jmp .geometry_type_unsupported

.is_wireframe_from_edge_color:
	mov r11,1
	call rasterize_edges_depth

	jmp .geometry_type_unsupported

.is_wireframe_interpolated_color:
	mov r11,2
	call rasterize_edges_depth

	jmp .geometry_type_unsupported

.is_face_from_solid_color:
	xor r11,r11
	call rasterize_faces_depth

	jmp .geometry_type_unsupported

.is_face_from_face_color:
	mov r11,1
	call rasterize_faces_depth

	jmp .geometry_type_unsupported

.is_face_interpolated_color:
	mov r11,2
	call rasterize_faces_depth

	jmp .geometry_type_unsupported

.is_text:
	call rasterize_text_depth


.geometry_type_unsupported:

	cmp qword [r14],0
	je .done

	mov r14,[r14]
	jmp .loop

.done:
	
	pop r14
	pop r11
	pop r10
	pop r9
	pop r8
	pop rcx
	pop rdx
	pop rsi
	
	ret

%endif	
