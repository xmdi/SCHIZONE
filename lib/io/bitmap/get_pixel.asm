%ifndef GET_PIXEL
%define GET_PIXEL

get_pixel:
; int {rax} get_pixel(void* {rdi}, int {esi}, int {edx}, int {ecx},
;		 int {r8d});
;	Gets pixel value at ({ecx},{r8d}) (from (0,0) @ top-left) in ARGB data
;	array starting at {rdi} for an {esi}x{edx} (HxW) image and returns the
;	value in {rax}.

	push rsi

	sub rsi,rcx
	imul rsi,rdx
	add rsi,r8
	shl rsi,2	; offset to pixel address

	mov rax,[rdi+rsi]

	pop rsi

	ret		; return

%endif
