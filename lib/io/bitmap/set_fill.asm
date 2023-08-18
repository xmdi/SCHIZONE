%ifndef SET_FILL
%define SET_FILL

; dependency
%include "lib/io/bitmap/set_pixel.asm"

set_fill:
; void set_fill(void* {rdi}, int {esi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d});
;	Fills the region at ({r8d},{r9d}) (from (0,0) @ top-left) 
;	in ARGB data array starting at {rdi} for an image of dimension
;	({edx},{ecx}) (WxH) to the color value in {esi}. All adjacent 
;	pixels of the same original color will be filled.

	push rax
	push rbx

	mov rax,rcx
	sub rax,r9
	dec rax
	imul rax,rdx
	add rax,r8
	shl rax,2	; offset to pixel address
	mov eax,dword [rdi+rax]	; target pixel color in rax
	
	call .loop
	jmp .ret
.loop:
	; if we are beyond the boundaries, return
	test r8,r8
	js .outside_image_boundaries
	test r9,r9
	js .outside_image_boundaries
	cmp r8,rdx
	jge .outside_image_boundaries
	cmp r9,rcx
	jge .outside_image_boundaries

	; check pixel color of target
	mov rbx,rcx
	sub rbx,r9
	dec rbx
	imul rbx,rdx
	add rbx,r8
	shl rbx,2	; offset to pixel address
	mov ebx,dword [rdi+rbx]	; current pixel color in rbx

	cmp eax,ebx	; if we are the same color as the original
	je .set_this_one	; set this pixel
	ret	

.set_this_one:
	call set_pixel	; set this pixel

	; recursive flood above
	push r9
	dec r9
	call .loop
	pop r9
	; recursive flood below
	push r9
	inc r9
	call .loop
	pop r9
	; recursive flood to left
	push r8
	dec r8
	call .loop
	pop r8
	; recursive flood to right
	push r8
	inc r8
	call .loop
	pop r8
	ret

.ret:
	pop rbx
	pop rax
.outside_image_boundaries:
	ret	

%endif
