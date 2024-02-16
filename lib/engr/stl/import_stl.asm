%ifndef IMPORT_STL
%define IMPORT_STL

; dependencies
%include "lib/math/vector/triangle_normal.asm"
%include "lib/io/read_chars.asm"
%include "lib/mem/heap_alloc.asm"
%include "lib/mem/heap_free.asm"

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
	push r10
	push r11
	push r13
	push r14
	push r15
	sub rsp,48
	movdqu [rsp+0],xmm0
	movdqu [rsp+8],xmm1
	movdqu [rsp+16],xmm2

	; TODO: FIX
	; assume all vertices are NOT reused. 3 unique vertices per triangle

	; skip useless STL header
	SYS_PUSH_SYSCALL_CLOBBERED_REGISTERS
	push rdi
	push rsi
	push rdx
	push rax
	mov rdi,rsi
	mov rsi,80
	mov rdx,SYS_SEEK_SET
	mov rax,SYS_LSEEK
	syscall
	pop rax
	pop rdx
	pop rsi
	pop rdi
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
	mov [.saved_value],rdi
	call heap_alloc	; allocate 24 or 32 bytes per num_triangles
	mov rbx,rax	; {rbx} is pointer to face structure

	mov edi,ecx
	imul edi,edi,72
	call heap_alloc	; allocate 72 bytes per num_triangles 
	mov rbp,rax	; {rbp} is pointer to point structure

	pop rdi	

	; populates the "output" structure
	mov eax,ecx
	imul eax,eax,3
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
	mov rax,12
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

	; here we go thru the vertex array counting unique vertices

	mov rax,[rdi+16]	; point array start
	mov rdx,rax
	add rdx,24		; start at second vertex
	mov rcx,1		; unique point counter
	mov r8,1		; outer loop counter
	
.unique_vertex_count_outer_loop:
	movsd xmm0,[rdx+0]	; x	
	movsd xmm1,[rdx+8]	; y
	movsd xmm2,[rdx+16]	; z

	xor r9,r9		; inner loop counter
	mov rbx,rax
.unique_vertex_count_inner_loop:
	comisd xmm0,[rbx+0]
	jne .no_match
	comisd xmm1,[rbx+8]
	jne .no_match
	comisd xmm2,[rbx+16]
	jne .no_match
	; match found, do not repeat this vertex
	jmp .match_found_stop_checking
	
.no_match:
	add rbx,24
	inc r9
	cmp r9,r8
	jl .unique_vertex_count_inner_loop
	inc rcx	; unique vertex found, increment counter
		
.match_found_stop_checking:
	inc r8
	add rdx,24
	cmp r8,[rdi+0]
	jl .unique_vertex_count_outer_loop

	; {rcx} contains number of unique vertices

	push rdi

	mov rdi,rcx
	imul rdi,rdi,24
	call heap_alloc	; allocate 24 bytes per vertex 
	mov rbp,rax	; {rbp} is pointer to reduced point structure

	mov rdi,[.saved_value]
	call heap_alloc	; allocate 24 or 32 bytes per num_triangles
	mov r15,rax	; {r15} is pointer to new face structure

	pop rdi	

;	now loop for the actual new point array
	mov rax,[rdi+16]	; original point array start
	mov r10,rbp		; reduced point array start
	mov rdx,rax
	add rdx,24		; start at second vertex
	mov r8,1		; outer loop counter
	mov r11,1
	mov r14,r15		; pointer into element of new face array
	add r14,8
	mov r13,1		; track vertex number within face

	; get first vertex
	movsd xmm0,[rax+0]
	movsd xmm1,[rax+8]
	movsd xmm2,[rax+16]
	movsd [r10+0],xmm0
	movsd [r10+8],xmm1
	movsd [r10+16],xmm2
	add r10,24

.unique_vertex_count_outer_loop2:
	movsd xmm0,[rdx+0]	; x	
	movsd xmm1,[rdx+8]	; y
	movsd xmm2,[rdx+16]	; z

	xor r9,r9		; inner loop counter
	mov rbx,rax
.unique_vertex_count_inner_loop2:
	comisd xmm0,[rbx+0]
	jne .no_match2
	comisd xmm1,[rbx+8]
	jne .no_match2
	comisd xmm2,[rbx+16]
	jne .no_match2
	; match found, do not repeat this vertex

	; correct the face array to the reduced vertex number
	; correct vertex number is at element # r9 (not value in r9), 
	; old vertex number in r8
	push rax
	push rcx
	push rdx
	push r10
	push r11

	xor rdx,rdx
	mov rax,r8
	mov rcx,3
	div rcx
	; remainder in {rdx}, quotient in {rax}
	shl rax,5
	shl rdx,3
	add rax,rdx
	add rax,r15;[rdi+24] ; {rax} now points to the target address in face array
	mov r10,rax

	xor rdx,rdx
	mov rax,r9
	mov r11,3
	div r11
	; remainder in {rdx}, quotient in {rax}
	shl rax,5
	shl rdx,3
	add rax,rdx
	add rax,r15;[rdi+24] ; {rax} now points to the target address in face array for correct vtx

	mov rax,[rax]
	mov [r10],rax

	pop r11
	pop r10
	pop rdx
	pop rcx
	pop rax
	
	inc r13
	cmp r13,3
	jl .dont_wrap
	add r14,8
	xor r13,r13
.dont_wrap:
	add r14,8
	jmp .match_found_stop_checking2
	
.no_match2:
	add rbx,24
	inc r9
	cmp r9,r8
	jl .unique_vertex_count_inner_loop2

	; unique vertex identified at {rdx}. put it in new array
	movsd [r10+0],xmm0
	movsd [r10+8],xmm1
	movsd [r10+16],xmm2
	add r10,24

	mov [r14],r11	
	inc r13
	cmp r13,3
	jl .dont_wrap2
	add r14,8
	xor r13,r13
.dont_wrap2:
	add r14,8
	inc r11

.match_found_stop_checking2:

	inc r8
	add rdx,24
	cmp r8,[rdi+0]
	jl .unique_vertex_count_outer_loop2

	; free unused data structures	
	push rdi
	mov rdi,[rdi+16]
	call heap_free
	mov rdi,[rsp+0]
	mov rdi,[rdi+24]
	call heap_free
	pop rdi
	
	; populate the data structure
	mov [rdi+0],rcx
	mov [rdi+16],rbp
	mov [rdi+24],r15

.ret:

	movdqu xmm0,[rsp+0]
	movdqu xmm1,[rsp+8]
	movdqu xmm2,[rsp+16]
	add rsp,48
	pop r15
	pop r14
	pop r13
	pop r11
	pop r10
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

.saved_value:
	dq 0

%endif
