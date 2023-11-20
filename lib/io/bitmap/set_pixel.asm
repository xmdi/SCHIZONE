%ifndef SET_PIXEL
%define SET_PIXEL

set_pixel:
; void set_pixel(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d});
;	Sets pixel at ({r8d},{r9d}) (from (0,0) @ top-left) in ARGB data
;	array starting at {rdi} for an {edx}x{ecx} (WxH) image to the 
;	value in {esi}. The 32nd bit of {rsi} indicates the y stacking direction:
;	0 for bottom-to-top formats (bmp) and 1 for top-to-bottom (framebuffer).

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

	mov rax,rsi
	and rax,0xFFFFFFFF

	mov rdi,SYS_STDOUT
	mov rsi,rax
	call print_int_h
	call print_buffer_flush
	call exit

	mov [rdi+rcx], dword eax

	pop rax
	pop rcx

	ret		; return

%endif
