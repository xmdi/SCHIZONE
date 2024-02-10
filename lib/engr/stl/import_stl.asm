%ifndef IMPORT_STL
%define IMPORT_STL

; dependencies
%include "lib/math/vector/triangle_normal.asm"
%include "lib/io/read_chars.asm"
%include "lib/mem/heap_alloc.asm"

import_stl:
; void import_stl(struct* {rdi}, uint {rsi}, bool {rdx});
; 	Imports the STL model at file descriptor at {rsi} into face structure 
;	at {rdi}.
;	Face structure contains colors if {rdx} high, otherwise is does not.

%if 0 ; sample face structure

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
	
	push rax
	push rbx
	push rcx
	push rdx
	push rbp
	push r8
	push r9
	sub rsp,16
	movdqu [rsp+0],xmm0

	; TODO: FIX
	; assume all vertices are NOT reused. 3 unique vertices per triangle

	; skip useless STL header
	SYS_PUSH_SYSCALL_CLOBBERED_REGISTERS
	push rsi
	push rdx
	push rax
	mov rsi,80
	mov rdx,SYS_SEEK_SET
	mov rax,SYS_LSEEK
	syscall
	pop rax
	pop rdx
	pop rsi
	SYS_POP_SYSCALL_CLOBBERED_REGISTERS

	; grab 4-byte triangle count
	push rdi
	push rsi
	push rdx
	mov rdi,rsi
	mov rsi,.triangle_count
	mov rdx,4
	call read_chars	
	pop rdx
	pop rsi
	pop rdi
	mov ecx,dword[.triangle_count]

	push rdi

	mov edi,ecx
	shl edx,3
	add edx,24
	imul edi,edx
	call heap_alloc	; allocate 24 or 32 bytes per num_triangles
	mov rbx,rax	; {rbx} is pointer to face structure
	
	mov edi,ecx
	imul edi,edi,72
	call heap_alloc	; allocate 72 bytes per num_triangles 
	mov rbp,rax	; {rbp} is pointer to point structure

	pop rdi	

	; populates the "output" structure
	mov eax,ecx
	imul eax,eax,9
	mov [rdi+0],rax
	mov [rdi+8],rcx
	mov [rdi+16],rbp
	mov [rdi+24],rbx

	; {edx} is the spacing between rows of face structure
	
	xor r9,r9	; counter for vertices in faces

.loop:
	push rdi
	push rsi
	push rdx
	mov rdi,rsi	
	mov rsi,.triangle_buffer
	mov rdx,50
	call read_chars
	pop rdx
	pop rsi
	pop rdi

	; populates the vertices
	mov r8,9
	xor rax,rax
.vertex_loop:
	movd xmm0,[.triangle_buffer+rax]
	cvtss2sd xmm0,xmm0
	movq [rbp],xmm0
	add rbp,8
	add rax,4
	dec r8
	jnz .vertex_loop

	; populates the faces
	mov [rbx],r9
	inc r9
	mov [rbx+8],r9
	inc r9
	mov [rbx+16],r9
	inc r9

	add rbx,rdx
	dec ecx
	jnz .loop

.ret:

	movdqu xmm0,[rsp+0]
	add rsp,16
	pop r9
	pop r8
	pop rbp
	pop rdx
	pop rcx
	pop rbx
	pop rax

	ret			; return

.triangle_count:
	dd 0

.triangle_buffer:
	times 50 db 0

%endif
