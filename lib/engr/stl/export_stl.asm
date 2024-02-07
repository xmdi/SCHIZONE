%ifndef EXPORT_STL
%define EXPORT_STL

; dependencies
%include "lib/math/vector/triangle_normal.asm"
%include "lib/io/print_chars.asm"

export_stl:
; void export_stl(uint {rdi}, struct* {rsi}, bool {rdx});
; 	Exports the face structure at {rsi} to the file descriptor {rdi} in STL format.
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
	
	push rbx
	push rcx
	push rdx
	push r8
	push r9
	push r10
	push r11
	sub rsp,16
	movdqu [rsp+0],xmm0

	; reset PRINT_BUFFER
	mov qword [PRINT_BUFFER_LENGTH],0

	mov r8,24
	shl rdx,3
	add rdx,24
	mov rbx,[rsi+24]	; address of first face definition
	mov rcx,[rsi+8]
	cmp rcx,0
	jbe .ret

	push rsi
	push rdx
	
	; print STL header
	mov rsi,.stl_header
	mov rdx,80
	call print_chars

	; print triangle count
	mov dword[.triangle_count],ecx
	mov rsi,.triangle_count
	mov rdx,4
	call print_chars

	pop rdx
	pop rsi

	pxor xmm0,xmm0

.loop:
	mov r9,[rbx]		; ID of first point on face
	imul r9,r8		
	add r9,[rsi+16]		; address of first point x-coord
	
	mov r10,[rbx+8]		; ID of second point on face
	imul r10,r8		
	add r10,[rsi+16]	; address of second point x-coord
	
	mov r11,[rbx+16]	; ID of third point on face
	imul r11,r8		
	add r11,[rsi+16]	; address of third point x-coord
		
	push rdi
	push rsi
	push rdx
	push rcx
	mov rdi,.normal_buffer	
	mov rsi,r9
	mov rdx,r10
	mov rcx,r11
	call triangle_normal	; compute triangle normal at .normal_buffer
	pop rcx
	pop rdx
	pop rsi
	pop rdi	

	; save normal information to buffer
	cvtsd2ss xmm0,[.normal_buffer+0]
	movd [.triangle_buffer+0],xmm0
	cvtsd2ss xmm0,[.normal_buffer+8]
	movd [.triangle_buffer+4],xmm0
	cvtsd2ss xmm0,[.normal_buffer+16]
	movd [.triangle_buffer+8],xmm0

	; save vertex 1 information to buffer
	cvtsd2ss xmm0,[r9+0]
	movd [.triangle_buffer+12],xmm0
	cvtsd2ss xmm0,[r9+8]
	movd [.triangle_buffer+16],xmm0
	cvtsd2ss xmm0,[r9+16]
	movd [.triangle_buffer+20],xmm0

	; save vertex 2 information to buffer
	cvtsd2ss xmm0,[r10+0]
	movd [.triangle_buffer+24],xmm0
	cvtsd2ss xmm0,[r10+8]
	movd [.triangle_buffer+28],xmm0
	cvtsd2ss xmm0,[r10+16]
	movd [.triangle_buffer+32],xmm0

	; save vertex 3 information to buffer
	cvtsd2ss xmm0,[r11+0]
	movd [.triangle_buffer+36],xmm0
	cvtsd2ss xmm0,[r11+8]
	movd [.triangle_buffer+40],xmm0
	cvtsd2ss xmm0,[r11+16]
	movd [.triangle_buffer+44],xmm0

	; print triangle information
	push rsi
	push rdx
	mov rsi,.triangle_buffer
	mov rdx,50
	call print_chars
	pop rdx
	pop rsi

	add rbx,rdx
	dec rcx
	jnz .loop

.ret:

	movdqu xmm0,[rsp+0]
	add rsp,16
	pop r11
	pop r10
	pop r9
	pop r8
	pop rdx
	pop rcx
	pop rbx

	ret			; return

.stl_header:
	db `I formally dedicate this STL file, along with all my productive `
	db `work, to Christ.	

.triangle_count:
	dd 0

.normal_buffer:
	times 3 dq 0.0

.triangle_buffer:
	times 50 db 0

%endif
