%ifndef MEMSET
%define MEMSET

memset:
; void memset(void* {rdi}, char {sil}, ulong {rdx});
;	Sets {rdx} bytes starting at address {rdi} to the byte value in {sil}.

	push rdi
	push rdx

.loop:
	mov byte [rdi],sil
	inc rdi
	dec rdx
	jnz .loop

	pop rdx
	pop rdi
	ret

%endif
