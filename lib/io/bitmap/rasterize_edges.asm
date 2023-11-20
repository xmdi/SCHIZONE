%ifndef RASTERIZE_EDGES
%define RASTERIZE_EDGES

; dependency
%include "lib/io/bitmap/set_pixel.asm"

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
	
	mov r11,[rax]
	shl r11,3
	add r11,r11
	add r11,r11	; {r11} points to the x value of the first point
	
	movsd xmm0,[r11]	; Pt_x
	movsd xmm1,[r11+8]	; Pt_y
	movsd xmm2,[r11+16]	; Pt_z

	mov

	cvtsd2si

	dec r15
	jnz .loop_edges

	


	ret

%endif
