%ifndef SET_PIXEL
%define SET_PIXEL

set_pixel:
; void set_pixel(void* {rdi}, int {esi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d});
;	Sets pixel at ({r8d},{r9d}) (from (0,0) @ top-left) in ARGB data
;	array starting at {rdi} for an {edx}x{ecx} (WxH) image to the 
;	value in {esi}.

	push rcx

	sub rcx,r9
	dec rcx
	imul rcx,rdx
	add rcx,r8
	shl rcx,2	; offset to pixel address

	mov [rdi+rcx], dword esi

	pop rcx

	ret		; return

%endif
