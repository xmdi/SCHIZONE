%ifndef SET_PIXEL
%define SET_PIXEL

set_pixel:
; void set_pixel(void* {rdi}, int {esi}, int {edx});
;	Sets pixel {edx} in ARGB data array starting at {rdi} to the
;	value in {esi}.

	mov [rdi+4*rdx],rsi

	ret		; return

%endif
