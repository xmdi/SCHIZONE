%ifndef RASTERIZE_EDGES
%define RASTERIZE_EDGES

; dependency
%include "lib/io/bitmap/set_line.asm"

rasterize_edges:
; void rasterize_edges(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 struct* {r8}, struct* {r9});
;	Rasterizes a set of edges described by the structure at {r9} from the
;	perspective described by the structure at {r8} to the {edx}x{ecx} (WxH)
;	image using the color value in the low 32 bits of {rsi} to the bitmap
;	starting at address {rdi}. The 32nd bit of {rsi} indicates the stacking
;	direction of the bitmap rows.

%if 0
.perspective_structure:
	dq 0.00 ; lookFrom_x	
	dq 0.00 ; lookFrom_y	
	dq 0.00 ; lookFrom_z	
	dq 0.00 ; lookAt_x	
	dq 0.00 ; lookAt_y	
	dq 0.00 ; lookAt_z	
	dq 0.00 ; upDir_x	
	dq 0.00 ; upDir_y	
	dq 0.00 ; upDir_z	
	dq 1.00	; zoom
%endif

%if 0
.edge_structure:
	dq 0 ; number of points (N)
	dq 0 ; number of edges (M)
	dq 0 ; starting address of point array (3N elements)
	dq 0 ; starting address of edge array (2M elements)
%endif

	push rax
	push r10
	push r11
	push r12
	push r13
	push r14
	push r15
	sub rsp,144
	movdqu [rsp+0],xmm0
	movdqu [rsp+16],xmm1
	movdqu [rsp+32],xmm2
	movdqu [rsp+48],xmm3
	movdqu [rsp+64],xmm4
	movdqu [rsp+80],xmm5
	movdqu [rsp+96],xmm6
	movdqu [rsp+112],xmm7
	movdqu [rsp+128],xmm8

	; Uy = (upDir)
	; Ux = (upDir)x(lookFrom-lookAt)

	; rasterized pt x = (Pt).(Ux)*zoom*width/2+width/2
	; rasterized pt y = -(Pt).(Uy)*zoom*height/2+height/2

	; precompute Ux*zoom and Uy*zoom

	movsd xmm3,[r8+48]
	mulsd xmm3,[r8+72] ; Uy*zoom(1)
	movsd xmm4,[r8+56]
	mulsd xmm4,[r8+72] ; Uy*zoom(2)
	movsd xmm5,[r8+64]
	mulsd xmm5,[r8+72] ; Uy*zoom(3)
	
	movsd xmm6,[r8+0]
	subsd xmm6,[r8+24]
	mulsd xmm6,[r8+72] ; Ux*zoom(1)
	movsd xmm7,[r8+8]
	subsd xmm7,[r8+32]
	mulsd xmm7,[r8+72] ; Ux*zoom(2)
	movsd xmm8,[r8+16]
	subsd xmm8,[r8+40]
	mulsd xmm8,[r8+72] ; Ux*zoom(3)

	; width/2 and height/2
	shr edx,1
	shr ecx,1	

	mov r15,[r9+8]	; number of edges in r15
	mov rax,[r9+24]
	;loop thru all edges

.loop_edges:

	; grab first point
	
	mov r10,[rax]
	shl r10,3
	add r10,r10
	add r10,r10	; {r10} points to the x value of the first point
	add r10,[r9+16]
	
	movsd xmm0,[r10]	; Pt_x
	movsd xmm1,[r10+8]	; Pt_y
	movsd xmm2,[r10+16]	; Pt_z

	mulsd xmm0,xmm6		
	mulsd xmm1,xmm7
	mulsd xmm2,xmm8
	addsd xmm0,xmm1
	addsd xmm0,xmm2		; Pt.Ux*zoom in {xmm0}

	cvtsd2si r11,xmm0	
	inc r11
	imul r11,rdx		; {r11} contains pixel 1 x-coord
	
	movsd xmm0,[r10]	; Pt_x
	movsd xmm1,[r10+8]	; Pt_y
	movsd xmm2,[r10+16]	; Pt_z

	mulsd xmm0,xmm3
	mulsd xmm1,xmm4
	mulsd xmm2,xmm5
	addsd xmm0,xmm1
	addsd xmm0,xmm2		; Pt.Uy*zoom in {xmm0}

	cvtsd2si r12,xmm0	
	neg r12
	inc r12
	imul r12,rcx		; {r12} contains pixel 1 y-coord

	add rax,8
	
	mov r10,[rax]
	shl r10,3
	add r10,r10
	add r10,r10	; {r10} points to the x value of the second point
	add r10,[r9+16]
	
	movsd xmm0,[r10]	; Pt_x
	movsd xmm1,[r10+8]	; Pt_y
	movsd xmm2,[r10+16]	; Pt_z

	mulsd xmm0,xmm6		
	mulsd xmm1,xmm7
	mulsd xmm2,xmm8
	addsd xmm0,xmm1
	addsd xmm0,xmm2		; Pt.Ux*zoom in {xmm0}

	cvtsd2si r13,xmm0	
	inc r13
	imul r13,rdx		; {r13} contains pixel 2 x-coord
	
	movsd xmm0,[r10]	; Pt_x
	movsd xmm1,[r10+8]	; Pt_y
	movsd xmm2,[r10+16]	; Pt_z

	mulsd xmm0,xmm3
	mulsd xmm1,xmm4
	mulsd xmm2,xmm5
	addsd xmm0,xmm1
	addsd xmm0,xmm2		; Pt.Uy*zoom in {xmm0}

	cvtsd2si r14,xmm0	
	neg r14
	inc r14
	imul r14,rcx		; {r14} contains pixel 2 y-coord

	push r8
	push r9
	push r10
	push r11
	mov r8,r11
	mov r9,r12
	mov r10,r13
	mov r11,r14
	shl rdx,1
	shl rcx,1
	call set_line
	shr rdx,1
	shr rcx,1
	pop r11
	pop r10
	pop r9
	pop r8

	dec r15
	jnz .loop_edges

	movdqu xmm0,[rsp+0]
	movdqu xmm2,[rsp+32]
	movdqu xmm3,[rsp+48]
	movdqu xmm4,[rsp+64]
	movdqu xmm5,[rsp+80]
	movdqu xmm6,[rsp+96]
	movdqu xmm7,[rsp+112]
	movdqu xmm8,[rsp+128]
	add rsp,144
	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop rax

	ret

%endif
