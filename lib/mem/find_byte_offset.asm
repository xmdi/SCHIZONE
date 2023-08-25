%ifndef FIND_BYTE_OFFSET
%define FIND_BYTE_OFFSET

find_byte_offset:
; int {rax} find_byte_offset(void* {rdi}, char {sil}, uint {rdx});
;	Searches {rdx} bytes of memory starting at address {rdi} for the
;	byte in {sil}. If found, returns the offset to this byte in memory
;	in {rax}. Otherwise, returns -1 in {rax}.

	push rdx
	xor rax,rax
.loop:
	cmp byte [rdi+rax],sil
	je .done
	inc rax
	dec rdx
	jnz .loop
	mov rax,-1
.done:
	pop rdx
	ret

%endif
