%ifndef SET_PIXEL
%define SET_PIXEL

set_pixel:
; void set_pixel(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d});
;	Sets pixel at ({r8d},{r9d}) (from (0,0) @ top-left) in ARGB data
;	array starting at {rdi} for an {edx}x{ecx} (WxH) image to the 
;	value in {esi}. The 32nd bit of {rsi} indicates the y stacking direction:
;	0 for bottom-to-top formats (bmp) and 1 for top-to-bottom (framebuffer).
;	Silently skips any pixel outside the image.

	cmp r8d,0
	jl .skip
	cmp r9d,0
	jl .skip
	cmp r8d,edx
	jge .skip
	cmp r9d,ecx
	jge .skip

	push rcx
	push rax

	mov rax,rsi
	shr rax,32
	test rax,1
	jne .framebuffer_stacking

.bitmap_stacking:
	sub rcx,r9
	dec rcx
	jmp .rejoin
.framebuffer_stacking:
	mov rcx,r9
.rejoin:
	imul rcx,rdx
	add rcx,r8
	shl rcx,2	; offset to pixel address

	mov rax,0xFFFFFFFF
	and rax,rsi

	mov [rdi+rcx], dword eax

	pop rax
	pop rcx
.skip:
	ret		; return

%endif
