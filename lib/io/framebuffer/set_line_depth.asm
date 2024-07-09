%ifndef SET_LINE_DEPTH
%define SET_LINE_DEPTH

; dependency
%include "lib/io/bitmap/set_pixel.asm"

set_line_depth:
; void set_line_depth(void* {rdi}, long*/long {rsi}, int {edx}, int {ecx},
;		 double* {r8},[6x0B,char,bool] {r9}, single* {r10})
;	Plots line with vertices described by 6 double-precision floats
;	starting at {r8} (projected x, projected y, projected depth)
;	in ARGB data array starting at {rdi} for an {edx}x{ecx} (WxH) image. 
;	{r9} contains color interpolation flag. If low bit of {r9} is high, 
;	{rsi} points to 2x1 ARGB color array (32 bpp). If low bit of {r9} 
;	is low, {rsi} contains solid line color (32 bpp). Pointer to 
;	single-precision depth buffer at {r10} (4*{ecx}*{edx} bytes). Line
; 	thickness in second-lowest byte of {r9}.

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

	mov rbp,r9	; save color boolean & line thickness from clobberin'

	and r9,0x1
	mov byte [.color_interp_flag],r9b
	mov [.depth_buffer_address],r10

	cmp r9,0
	je .no_color_interp

	mov rax,[rsi]
	mov [.init_colors],rax

.no_color_interp:

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

	; pt to check/plot at ({xmm10},{xmm11}) ; could be ints and constantly converted via cvtsi2sd

	;;;;;; todo, adjust line endpoints to be within screen boundary
	;;;;;; oops nvm for gradient
	mov rax,rbp
	shr rax,8
	test rax,0x1
	jnz .odd_no

	movsd xmm5,[r8+32]; y1
	movsd xmm2,[r8+24]; x1
	movsd xmm4,[r8+8]; y0
	movsd xmm0,[r8]; x0
	
	subsd xmm5,xmm4
	mulsd xmm5,xmm5
	subsd xmm2,xmm0
	mulsd xmm2,xmm2
	addsd xmm5,xmm2
	sqrtsd xmm5,xmm5 ; L in xmm5
	
	; quickly save length of line segment to memory
	movq [.line_segment_length],xmm5

	movsd xmm6,[r8+32]; y1
	subsd xmm6,[r8+8] ; y0
	pslld xmm6,1
	psrld xmm6,1
	divsd xmm6,xmm5
	mulsd xmm6,[.half]
	
	movsd xmm7,[r8+24]; x1
	subsd xmm7,[r8+0] ; x0
	pslld xmm7,1
	psrld xmm7,1
	divsd xmm7,xmm5
	mulsd xmm7,[.half]
	
.odd_no:

	movsd xmm1,[r8+16]; z0
	movsd xmm3,[r8+40]; z1

	movsd xmm15,[r8+32]; y1
	cvtsd2si r11,xmm0

	movsd xmm14,[r8+24]; x1
	cvtsd2si r10,xmm2
	
	movsd xmm13,[r8+8]; y0
	cvtsd2si r9,xmm0
	
	movsd xmm12,[r8]; x0
	cvtsd2si r8,xmm0
	
	test rax,0x1
	jnz .odd_no2

	; correction offset for even line thicknesses
	addsd xmm12,xmm6
	addsd xmm14,xmm6
	addsd xmm13,xmm7
	addsd xmm15,xmm7

.odd_no2:

	cvtsd2si r11,xmm15
	cvtsd2si r10,xmm14
	cvtsd2si r9,xmm13
	cvtsd2si r8,xmm12

;	test rbp,0x1	
;	jz .skip_color_interp
	mov [.colors_array],rsi
.skip_color_interp:

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
	neg r12		; {r12} is x-width of line segment (abs)
.abs_dx:
	mov r13,r11
	sub r13,r9
	test r13,r13
	jns .abs_dy
	neg r13		; {r13} is y-width of line segment (abs)
.abs_dy:
	
	cmp r13,r12
	jge .plot_line_up

; these labels preprocess lines to ensure they are increasing in their coords

.plot_line_down: ; not steep
	cmp r8,r10
	jle .plot_down	; plot line down forwards
	mov r12,r10	
	mov r10,r8
	mov r8,r12
	mov r12,r11
	mov r11,r9
	mov r9,r12

	test rbp,0x1		; if we swapped points, also swap colors 
	jz .skip_color_interp_down
	mov eax,[.init_colors]
	mov [rsi+4],eax	
	mov eax,[.init_colors+4]
	mov [rsi],eax
.skip_color_interp_down:

	jmp .plot_down	; plot line down backwards

.plot_line_up: ; steep

	cmp r9,r11
	jle .plot_up	; plot line up forwards
	mov r12,r10
	mov r10,r8
	mov r8,r12
	mov r12,r11
	mov r11,r9
	mov r9,r12

	test rbp,0x1		; if we swapped points, also swap colors 
	jz .skip_color_interp_up	
	mov eax,[.init_colors]
	mov [rsi+4],eax	
	mov eax,[.init_colors+4]
	mov [rsi],eax
.skip_color_interp_up:

	; plot line up backwards

.plot_up:
	; save x0,y0 to memory
	mov [.init_x0],r8
	mov [.init_y0],r9

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

	mov byte [.direction_byte],0b0 ; x-dir thickness
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
	; save x0,y0 to memory
	mov [.init_x0],r8
	mov [.init_y0],r9

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

	mov byte [.direction_byte],byte 0b1 ; y-dir thickness

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
	push rsi

	; x in {r8}
	cvtsi2sd xmm0,r8
	subsd xmm0,[.x0]
	mulsd xmm0,[.depth_slope]
	addsd xmm0,[.z0]
	; depth of pixel of interest in {xmm0} (double precision)

	cvtsd2ss xmm0,xmm0 ; does work LOL

	movss xmm15,xmm0	

	mov rax,r8 ; x coord
	mov rbx,r9 ; y coord

	cmp byte [.color_interp_flag],byte 0 
	je .color_computed

	push r13
	push r14
	push r15

	mov r15,[.colors_array]
	xor r13,r13

	mov r14,r8
	sub r14,[.init_x0]
	cvtsi2sd xmm4,r14
	mulsd xmm4,xmm4
	
	mov r14,r9
	sub r14,[.init_y0]
	cvtsi2sd xmm5,r14
	mulsd xmm5,xmm5
	
	addsd xmm4,xmm5
	sqrtsd xmm4,xmm4
	divsd xmm4,[.line_segment_length]  ; potentially pull out of loop TODO
	comisd xmm4,[.one]
	jbe .no_round
	movsd xmm4,[.one]

.no_round:
	; {xmm4} is 0->1 along line segmenti

	; interpolation of R
	movzx r14,byte [r15+2]
	cvtsi2sd xmm0,r14
	movzx r14,byte [r15+6]
	cvtsi2sd xmm1,r14
	subsd xmm1,xmm0
	mulsd xmm1,xmm4
	addsd xmm0,xmm1
	cvtsd2si r14,xmm0	
	
	shl r14,16
	or r13,r14
	
	; interpolation of G
	movzx r14,byte [r15+1]
	cvtsi2sd xmm0,r14			; 0xFF
	movzx r14,byte [r15+5]			; 0x00
	cvtsi2sd xmm1,r14
	subsd xmm1,xmm0				; -255.0
	mulsd xmm1,xmm4				; -255.0*1.01
	addsd xmm0,xmm1				; 0xFF-0x100
	cvtsd2si r14,xmm0			; 0x100->256.0
	
	shl r14,8
	or r13,r14
	
	; interpolation of B
	movzx r14,byte [r15+0]
	cvtsi2sd xmm0,r14
	movzx r14,byte [r15+4]
	cvtsi2sd xmm1,r14
	subsd xmm1,xmm0
	mulsd xmm1,xmm4
	addsd xmm0,xmm1
	cvtsd2si r14,xmm0
	
	or r13,r14

	mov rsi,r13 ; color of pixel of interest in {rsi}
	and rsi,0x00FFFFFF

	pop r15
	pop r14
	pop r13


.color_computed:

	mov rbp,[rsp+8]

	; put the pixel
	push r8
	push r9
	mov r8,rax
	mov r9,rbx

	cmp byte [.direction_byte],byte 0b1
	je .ydir

.xdir:
;;;
	mov rax,rbp
	shr rax,8
	and rax,0xFF
	cmp rax,1
	jle .loop_process_no_extra_thickness
	test rax,0b1
	jnz .loop_process_odd_thickness
	shr rax,1
	sub r8,rax
	call .set_pixel_and_depth
	add r8,rax
	shl rax,1

.loop_process_odd_thickness:
	dec rax
	shr rax,1
	test rax,0x7F
	jz .loop_process_no_extra_thickness

.loop_process_line_thickness_loop:
	add r8,rax
	call .set_pixel_and_depth
	sub r8,rax
	sub r8,rax
	call .set_pixel_and_depth
	add r8,rax
	dec rax
	jnz .loop_process_line_thickness_loop

.loop_process_no_extra_thickness:
;;;
	call .set_pixel_and_depth
	jmp .done_dir

.ydir:
;;;
	mov rax,rbp
	shr rax,8
	and rax,0xFF
	cmp rax,1
	jle .loop_process_no_extra_thickness2
	test rax,0b1
	jnz .loop_process_odd_thickness2
	shr rax,1
	sub r9,rax
	call .set_pixel_and_depth
	add r9,rax
	shl rax,1

.loop_process_odd_thickness2:
	dec rax
	shr rax,1
	test rax,0x7F
	jz .loop_process_no_extra_thickness2

.loop_process_line_thickness_loop2:
	add r9,rax
	call .set_pixel_and_depth
	sub r9,rax
	sub r9,rax
	call .set_pixel_and_depth
	add r9,rax
	dec rax
	jnz .loop_process_line_thickness_loop2

.loop_process_no_extra_thickness2:
;;;

	call .set_pixel_and_depth

.done_dir:
	pop r9
	pop r8

.too_deep_to_put_pixel:

	pop rsi
	pop rbp
	pop rbx
	pop rax

	ret

.vertical_line:
	
	mov byte [.direction_byte],0b0 ; x-dir thickness
	
	cmp r9,r11
	jl .pre_loop_vertical
	mov rax,r9
	mov r9,r11
	mov r11,rax	

	test rbp,0x1		; if we swapped points, also swap colors 
	jz .skip_color_interp_vertical
	mov rsi,[.colors_array]	

	mov eax,[.init_colors]
	mov [rsi+4],eax	
	mov eax,[.init_colors+4]
	mov [rsi],eax
	
.skip_color_interp_vertical:

.pre_loop_vertical:

	mov [.init_x0],r8
	mov [.init_y0],r9

.loop_vertical:	

	push rax
	push rsi
	push rbp
	
	mov byte [.direction_byte],0b0 ; x-dir thickness
	
	call .process_pixel

.loop_vertical_no_extra_thickness:
	pop rbp
	pop rsi
	pop rax

	inc r9
	cmp r9,r11
	jle .loop_vertical

	jmp .ret

.horizontal_line:

	mov byte [.direction_byte],0b1 ; y-dir thickness
	
	cmp r8,r10
	jl .pre_loop_horizontal
	mov rax,r8
	mov r8,r10
	mov r10,rax	

	test rbp,0x1		; if we swapped points, also swap colors 
	jz .skip_color_interp_horizontal
	mov rsi,[.colors_array]	
	mov eax,[.init_colors]
	mov [rsi+4],eax	
	mov eax,[.init_colors+4]
	mov [rsi],eax

.skip_color_interp_horizontal:

.pre_loop_horizontal:

	mov [.init_x0],r8
	mov [.init_y0],r9

.loop_horizontal:

	push rax
	push rsi
	push rbp

	mov byte [.direction_byte],0b1 ; y-dir thickness

	call .process_pixel
	
	pop rbp
	pop rsi
	pop rax
	
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

.set_pixel_and_depth:

	push rbp

	mov rbp,r9
	imul rbp,rdx
	add rbp,r8
	shl rbp,2 ; {rbp} contains byte number for pixel of interest
	add rbp,[.depth_buffer_address]	; {rbp} points to depth for pixel of interest
.b:

	movss xmm1,[rbp]

	movss xmm2,xmm15

	subss xmm2,xmm1
.c:
	comiss xmm2,dword [.wireframe_depth_threshold]

	jb .too_deep

	call set_pixel
	movss [rbp],xmm15

.too_deep:

	pop rbp

	ret

.vertices_copy:
	times 6 dq 0.0
.one:
	dq 1.0
.depth_slope: ; (z1-z0)/(x1-x0)
	dq 0.0
.x0:
	dq 0.0
.z0:
	dq 0.0
.half:	; half a pixel
	dq 0.5
.depth_buffer_address:
	dq 0
.wireframe_depth_threshold:
	dd 0.1;	dd 1.0
.colors_array:
	dq 0
.init_colors:
	times 2 dd 0
.line_segment_length:
	dq 0.0	
.init_x0:
	dq 0
.init_y0:
	dq 0
.color_interp_flag:
	db 0
.direction_byte:
	db 0
%endif
