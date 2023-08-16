%ifndef GET_PIXEL
%define GET_PIXEL

get_pixel:
; int {rax} get_pixel(void* {rdi}, int {esi}, int {edx}, int {ecx},
;		 int {r8d});
;	Gets pixel value at ({ecx},{r8d}) (from (0,0) @ top-left) in ARGB data
;	array starting at {rdi} for an {esi}x{edx} (WxH) image and returns the
;	value in {rax}.

	push rdx

	sub rdx,r8
	dec rdx
	imul rdx,rsi
	add rdx,rcx
	shl rdx,2	; offset to pixel address

	mov rax,[rdi+rdx]

	pop rdx

	ret		; return

%endif
