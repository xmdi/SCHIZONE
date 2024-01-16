%ifndef SET_TEXT
%define SET_TEXT

; dependency
%include "lib/io/bitmap/set_pixel.asm"

set_text:
; void set_text(void* {rdi}, int {esi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, char* {r11}, void* {r12});
;	Renders null-terminated character array starting at {r11} beginning 
;	at pixel ({r8d},{r9d}) (from (0,0) @ top-left) in ARGB data array 
;	starting at {rdi} for an {edx}x{ecx} (WxH) image in the color value
;	in {esi}. Font defined at {r12} and font scaling in {r10}.

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

.letter_loop:
	xor rbp,rbp
	mov bpl,byte [r11]
	cmp rbp,32
	jl .unknown_char
	cmp rbp,126
	jg .unknown_char
	sub rbp,32
	jmp .adjust_char
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

	call set_pixel
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
	mov rbp,8
	imul rbp,r10
	add r8,rbp
	mov [rsp+56],r8
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

%endif
