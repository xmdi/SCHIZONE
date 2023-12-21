%ifndef FRAMEBUFFER_3D_RENDER_INIT
%define FRAMEBUFFER_3D_RENDER_INIT

%include "lib/mem/memset.asm"
; void memset(void* {rdi}, char {sil}, ulong {rdx});

%include "lib/mem/memcopy.asm"
; void memcopy(long* {rdi}, long* {rsi}, ulong {rdx});

%include "lib/io/framebuffer/framebuffer_mouse_poll.asm"
; void framebuffer_mouse_poll(void);

%include "lib/io/bitmap/set_foreground.asm"
; void set_foreground(void* {rdi}, void* {rsi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});

%include "lib/io/framebuffer/framebuffer_clear.asm"
; void framebuffer_clear(uint {rdi});

%include "lib/io/framebuffer/framebuffer_flush.asm"
; void framebuffer_flush(void);

%include "lib/io/bitmap/set_pixel.asm"
; void set_pixel(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d});

%include "lib/io/bitmap/set_line.asm"
; void set_line(void* {rdi}, int {esi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});

%include "lib/io/bitmap/rasterize_edges.asm"
; void rasterize_edges(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 struct* {r8}, struct* {r9});

%include "lib/math/vector/normalize_3.asm"
; void normalize_3(double* {rdi});

%include "lib/math/vector/perpendicularize_3.asm"
; void perpendicularize_3(double* {rdi}, double* {rsi});

%include "lib/math/expressions/trig/sine.asm"
; double {xmm0} sine(double {xmm0}, double {xmm1});

%include "lib/math/expressions/trig/cosine.asm"
; double {xmm0} cosine(double {xmm0}, double {xmm1});

%include "lib/math/matrix/matrix_multiply.asm"
; void matrix_multiply(double* {rdi}, double* {rsi}, double* {rdx}, uint {rcx}
;	uint {r8}, uint {r9});

%include "lib/math/vector/cross_product_3.asm"
; void cross_product_3(double* {rdi}, double* {rsi}, double* {rdx});

framebuffer_3d_render_init:
; void framebuffer_3d_render_init(void);

; No error handling; deal with it.

; NOTE: NEED TO RUN THIS AS SUDO

	call heap_init

	call framebuffer_init
	
	call framebuffer_mouse_init

	mov rdi,[framebuffer_init.framebuffer_size]
	call heap_alloc
	mov r15,rax	; buffer to combine multiple layers

	; clear the screen to start
	mov rdi,0xFF000000
	call framebuffer_clear

	; perpendicularize the Up-direction vector
	mov rdi,.perspective_structure+48
	mov rsi,.perspective_structure+0
	call perpendicularize_3

	; compute rightward direction
	mov rdi,.view_axes_old+0
	mov rsi,.perspective_structure+48
	mov rdx,.perspective_structure+0
	call cross_product_3	

	mov rdi,.view_axes_old+24
	mov rsi,.perspective_structure+48
	mov rdx,24
	call memcopy

	movsd xmm15,[.perspective_structure+0]
	subsd xmm15,[.perspective_structure+24]
	movsd [.view_axes_old+48],xmm15
	movsd xmm15,[.perspective_structure+8]
	subsd xmm15,[.perspective_structure+32]
	movsd [.view_axes_old+56],xmm15
	movsd xmm15,[.perspective_structure+16]
	subsd xmm15,[.perspective_structure+40]
	movsd [.view_axes_old+64],xmm15

	; normalize the axes
	mov rdi,.view_axes_old+0
	call normalize_3
	mov rdi,.view_axes_old+24
	call normalize_3
	mov rdi,.view_axes_old+48
	call normalize_3

	; copy up-direction into structure
	mov rdi,.perspective_structure+48
	mov rsi,.view_axes_old+24
	mov rdx,24
	call memcopy

	; copy looking direction into structure
	movsd xmm15,[.view_axes_old+48]
	addsd xmm15,[.perspective_structure+24]
	movsd [.perspective_structure+0],xmm15
	movsd xmm15,[.view_axes_old+56]
	addsd xmm15,[.perspective_structure+32]
	movsd [.perspective_structure+8],xmm15
	movsd xmm15,[.view_axes_old+64]
	addsd xmm15,[.perspective_structure+40]
	movsd [.perspective_structure+16],xmm15

	; project & rasterize the cube onto the framebuffer
	mov rdi,[framebuffer_init.framebuffer_address]
	mov rsi,0x1FFFFA500
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]
	mov r8,.perspective_structure
	mov r9,.edge_structure
	call rasterize_edges	
	
	call framebuffer_flush
	
	; copy this to the intermediate buffer to start
	mov rdi,r15
	mov rsi,[framebuffer_init.framebuffer_address]
	mov rdx,[framebuffer_init.framebuffer_size]
	call memcopy
	
	ret

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
	times 6 dq 0.0
.zoom_old:
	dq 0.0

%endif	
