%ifndef EXPORT_STL
%define EXPORT_STL

; dependency
%include "lib/math/vector/triangle_normal.asm"

export_stl:
; void export_stl(uint {rdi}, struct* {rsi}, bool {rdx});
; 	Exports the face structure at [rsi} to the file descriptor {rdi} in STL format.
;	Face structure contains colors if {rdx} high, otherwise is does not.
;	Note: Clears the PRINT_BUFFER (does not flush) at routine start.

%ifdef 0 ; sample face structure

.faces_top_structure:
	dq 99 ; number of points (N)
	dq 99 ; number of faces (M)
	dq .points ; starting address of point array (3N elements)
	dq .faces ; starting address of face array 
		;	(3M elements if no colors)
		;	(4M elements if colors)

.points:
	dq 0.5,0.5,0.0
	dq -0.5,0.5,0.0 ; ...

.faces:
	
	dq 13,12,14,0x1FF0000FF
	dq 14,12,15,0x1FF0000FF ; ...

%endif

	sub rsp,48
	movdqu [rsp],xmm0
	movdqu [rsp+16],xmm1
	movdqu [rsp+32],xmm2

	; start at beginning of PRINT_BUFFER
	mov qword [PRINT_BUFFER_LENGTH],0

	shl rdx,3
	add rdx,24
	mov rbx,[rsi+24]
	mov rcx,[rsi+8]
	cmp rcx,0
	jbe .ret
.loop:
	mov rax,[rbx]
	mov ; TODO more here using normal calculation etc.

	add rbx,rdx
	dec rcx
	jnz .loop

.ret:
	movdqu xmm0,[rsp]
	movdqu xmm1,[rsp+16]
	movdqu xmm2,[rsp+32]
	add rsp,48

	ret			; return

%endif
