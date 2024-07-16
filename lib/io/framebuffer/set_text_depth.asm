%ifndef SET_TEXT_DEPTH
%define SET_TEXT_DEPTH

; dependency
%include "lib/io/bitmap/set_pixel.asm"
%include "lib/debug/debug.asm"

set_text_depth:
; void set_text(void* {rdi}, int {esi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, char* {r11},
; 		void* {r12}, single* {r13});
;	Renders null-terminated character array starting at {r11} beginning 
;	at pixel ({r8d},{r9d}) (from (0,0) @ top-left) in ARGB data array 
;	starting at {rdi} for an {edx}x{ecx} (WxH) image in the color value
;	in {esi}. Font defined at {r12} and font scaling in {r10}. Depth buffer
; 	at {r13}.

	push rbp
	push r8
	push r9
	push rdi
	push rsi
	push rdx
	push rcx
	push rbx
	push rax
	push r8
	push r9
	push r10 ; track the x
	push r11 ; track the y
	push r12 
	push r13 
	push r14 
	push r15
	; r8 always stores the left x pixel
	; r9 stores the current y pixel
	
	mov [.depth_buffer_address],r13

.letter_loop:
	xor rbp,rbp
	mov bpl,byte [r11]
	cmp rbp,10
	je .newline
	cmp rbp,32
	jl .unknown_char
	cmp rbp,126
	jg .unknown_char
	sub rbp,32
	jmp .adjust_char
.newline:
	mov r8,[rsp+120]
	mov [rsp+56],r8
	mov r9,[rsp+48]
	mov rbp,r10
	shl rbp,4
	add r9,rbp
	mov [rsp+48],r9
	jmp .next_letter

.unknown_char:
	mov rbp,95
.adjust_char:
	shl rbp,3
	add rbp,[rsp+24]

	mov r12,8
.row_loop:
	mov r8,[rsp+56]
	mov bl, byte [rbp]
	mov r14,8
.col_loop:
	mov r13b,bl
	test r13b, byte 0b10000000
	jz .no_pixel

	mov rax,r10
.scale_loop_x:
	mov r15,r10
	push r9
.scale_loop_y:
	push r8
;	add r8,r14

	call .set_pixel_and_depth
	pop r8
	inc r9
	dec r15
	jnz .scale_loop_y
	pop r9
	inc r8
	dec rax
	jnz .scale_loop_x
	jmp .rendered_pixels

.no_pixel:
	add r8,r10

.rendered_pixels:
	shl bl,1
	dec r14
	jnz .col_loop

	inc rbp
	add r9,r10 ; was inc r9
	
	dec r12
	jnz .row_loop

	mov r9,[rsp+48]
	mov r8,[rsp+56]
	mov rbp,r10
	shl rbp,3
	add r8,rbp
	mov [rsp+56],r8
.next_letter:
	inc r11
	cmp byte [r11],0
	jnz .letter_loop

	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rax
	pop rbx
	pop rcx
	pop rdx
	pop rsi
	pop rdi
	pop r9
	pop r8
	pop rbp

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
