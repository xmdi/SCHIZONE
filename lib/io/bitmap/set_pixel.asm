%ifndef SET_PIXEL
%define SET_PIXEL

set_pixel:
; void set_pixel(void* {rdi}, int {esi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d});
;	Sets pixel at ({r8d},{r9d}) (from (0,0) @ top-left) in ARGB data
;	array starting at {rdi} for an {edx}x{ecx} (HxW) image to the 
;	value in {esi}.

	push rdx

	sub rdx,r8
	imul rdx,rcx
	add rdx,r9
	shl rdx,2	; offset to pixel address

	mov [rdi+rdx],rsi

	pop rdx

	ret		; return

%endif
