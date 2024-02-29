%ifndef ASSEMBLE_FRAME_ELEMENTS
%define ASSEMBLE_FRAME_ELEMENTS

; dependencies
%include "lib/math/vector/distance_3.asm"

assemble_frame_elements:
; void assemble_frame_elements(struct* {rdi});
; 	Assembles stiffness matrix at [{rdi}+48] for 3D frame element system
;	characterized by the 3D frame element system defined at {rdi}.

%if 0 ; 3D frame FEA system has this form:
.3D_FRAME:
		dq 0 ; number of nodes (6 DOF per node)
		dq 0 ; number of elements
		dq 0 ; number of element types
		dq 0 ; pointer to node coordinate array
			; each row: (double) x,y,z
		dq 0 ; pointer to element array 
			; each row: (long) nodeID_A,nodeID_B,elementType
		dq 0 ; pointer to element type matrix
			; each row (double) E,G,A,Iy,Iz,J,Vx,Vy,Vz
		dq 0 ; pointer to stiffness matrix (K)
		dq 0 ; pointer to known forcing array (F)
%endif

; 12x12 frame element stiffness matrix has the form:
;	C1 = EA/L,	C2 = 12EIz/L^3,		C3 = 6EIz/L^2
;	C4 = GL/L,	C5 = 12EIy/L^3,		C6 = 6EIy/L^2
;	C7 = 4EIz/L,	C8 = 2EIz/L
;	C9 = 4EIy/L,	C10 = 2EIy/L
;  K=	[ C1 0 0 0 0 0 -C1 0 0 0 0 0 ]
;	[ 0 C2 0 0 0 C3 0 -C2 0 0 0 C3 ]
;	[ 0 0 C5 0 -C6 0 0 0 -C5 0 -C6 0 ]
;	[ 0 0 0 C4 0 0 0 0 0 -C4 0 0 ]
;	[ 0 0 -C6 0 C9 0 0 0 C6 0 C10 0 ]
;	[ 0 C3 0 0 0 C7 0 -C3 0 0 0 C8 ]
;	[ -C1 0 0 0 0 0 C1 0 0 0 0 0 ]
;	[ 0 -C2 0 0 0 -C3 0 C2 0 0 0 -C3 ]
;	[ 0 0 -C5 0 C6 0 0 0 C5 0 C6 0 ]
;	[ 0 0 0 -C4 0 0 0 0 0 C4 0 0 ]
;	[ 0 0 -C6 0 C10 0 0 0 C6 0 C9 0 ]
;	[ 0 C3 0 0 0 C8 0 -C3 0 0 0 C7 ]
	
;	loop thru elements
;		generate local elemental stiffness matrix
;		transform elemental stiffness matrix
;		populate global stiffness matrix




	mov rsi,[rdi+40] ; element type array
	

	mov rdx,[rdi+8]
	cmp rdx,0
	jle .no_els

	mov r8,[rdi+32]	; start of element array in {r8}

.element_loop:
	mov r9,[r8+0]	; nodeA
	mov r10,[r8+8]	; nodeB
	mov r11,[r8+16] ; element type
	imul r9,r9,24
	imul r10,r10,24
	imul r11,r11,72
	add r11,rsi

	push rdi
	push rsi
	mov rsi,[rdi+24]
	mov rdi,rsi
	add rdi,r9
	add rsi,r10
	call distance_3
	movsd xmm15,[.one]
	divsd xmm15,xmm0 ; 1/L in {xmm15}
	pop rsi
	pop rdi	
	movsd xmm14,xmm15
	mulsd xmm14,xmm15 ; 1/L^2 in {xmm14}
	movsd xmm13,xmm14 
	mulsd xmm13,xmm15 ; 1/L^3 in {xmm13}

	; C1
	movsd xmm1,[r11+0]
	mulsd xmm1,[r11+16]
	mulsd xmm1,xmm15

	; C2
	movsd xmm2,[.twelve]
	mulsd xmm2,[r11+0]
	mulsd xmm2,[r11+32]
	mulsd xmm2,xmm13

	; C3
	movsd xmm3,[.six]
	mulsd xmm3,[r11+0]
	mulsd xmm3,[r11+32]
	mulsd xmm3,xmm14

	; C4
	movsd xmm4,[r11+8]
	mulsd xmm4,[r11+40]
	mulsd xmm4,xmm15

	; C5
	movsd xmm5,[.twelve]
	mulsd xmm5,[r11+0]
	mulsd xmm5,[r11+24]
	mulsd xmm5,xmm13

	; C6
	movsd xmm6,[.six]
	mulsd xmm6,[r11+0]
	mulsd xmm6,[r11+24]
	mulsd xmm6,xmm14

	; C7
	movsd xmm7,[.four]
	mulsd xmm7,[r11+0]
	mulsd xmm7,[r11+32]
	mulsd xmm7,xmm15

	; C8
	movsd xmm8,[.two]
	mulsd xmm8,[r11+0]
	mulsd xmm8,[r11+32]
	mulsd xmm8,xmm15

	; C9
	movsd xmm9,[.four]
	mulsd xmm9,[r11+0]
	mulsd xmm9,[r11+24]
	mulsd xmm9,xmm15

	; C10
	movsd xmm10,[.two]
	mulsd xmm10,[r11+0]
	mulsd xmm10,[r11+24]
	mulsd xmm10,xmm15

	; TODO maybe init entire Kel to zeros

	movq [.Kel+0],xmm1
	movq [.Kel+624],xmm1
	mulsd xmm1,[.neg]
	movq [.Kel+48],xmm1
	movq [.Kel+576],xmm1

	movq [.Kel+104],xmm2
	movq [.Kel+728],xmm2
	mulsd xmm2,[.neg]
	movq [.Kel+152],xmm2
	movq [.Kel+680],xmm2

	movq [.Kel+136],xmm3
	movq [.Kel+184],xmm3
	movq [.Kel+488],xmm3
	movq [.Kel+1064],xmm3
	mulsd xmm3,[.neg]
	movq [.Kel+536],xmm3
	movq [.Kel+712],xmm3
	movq [.Kel+760],xmm3
	movq [.Kel+1112],xmm3
	
	movq [.Kel+312],xmm4
	movq [.Kel+936],xmm4
	mulsd xmm4,[.neg]
	movq [.Kel+360],xmm4
	movq [.Kel+888],xmm4

	movq [.Kel+208],xmm5
	movq [.Kel+256],xmm5
	mulsd xmm5,[.neg]
	movq [.Kel+784],xmm5
	movq [.Kel+832],xmm5

	movq [.Kel+448],xmm6
	movq [.Kel+800],xmm6
	movq [.Kel+848],xmm6
	movq [.Kel+1024],xmm6
	mulsd xmm6,[.neg]
	movq [.Kel+224],xmm6
	movq [.Kel+272],xmm6
	movq [.Kel+400],xmm6
	movq [.Kel+976],xmm6
	
	movq [.Kel+520],xmm7
	movq [.Kel+1144],xmm7

	movq [.Kel+568],xmm8
	movq [.Kel+1096],xmm8

	movq [.Kel+416],xmm9
	movq [.Kel+1040],xmm9

	movq [.Kel+464],xmm10
	movq [.Kel+992],xmm10

	

	add r8,24
	dec rdx
	jnz .element_loop

.no_els:




.ret:

	ret		; return
.neg:
	dq -1.0
.one:
	dq 1.0
.two:
	dq 2.0
.four:
	dq 4.0
.six:
	dq 6.0
.twelve:
	dq 12.0
.Kel:
	times 1152 db 0	; initialize 12x12 matrix of 0.0

.Kel_trans:
	times 1152 db 0	; initialize 12x12 matrix of 0.0

%endif
