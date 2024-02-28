%ifndef ASSEMBLE_FRAME_ELEMENTS
%define ASSEMBLE_FRAME_ELEMENTS

; dependencies

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
;	[ 0 C3 0 0 0 C7 0 -C3 0 0 0 C7 ]
;	[ -C1 0 0 0 0 0 C1 0 0 0 0 0 ]
;	[ 0 -C2 0 0 0 -C3 0 C2 0 0 0 -C3 ]
;	[ 0 0 -C5 0 C6 0 0 0 C5 0 C6 0 ]
;	[ 0 0 0 -C4 0 0 0 0 0 C4 0 0 ]
;	[ 0 0 -C6 0 C10 0 0 0 C6 0 C9 0 ]
;	[ 0 C3 0 0 0 C8 0 -C3 0 0 0 C7 ]
	
; 	loop thru element types
;		construct baseline elemental stiffness matrix per above
;		loop thru elements
;			if they match type
;				transform elemental stiffness matrix
;				populate global stiffness matrix


	mov rsi,[rdi+40] ; element type array

	mov rcx,[rdi+16]
	cmp rcx,0
	jle .ret

.element_type_loop:
	;;;;;;; each row (double) E,G,A,Iy,Iz,J,Vx,Vy,Vz
	movsd xmm0,[rsi+0]

	

	mov rdx,[rdi+8]
	cmp rdx,0
	jle .no_els

.element_loop:

	dec rdx
	jnz .element_loop

.no_els:
	dec rcx
	jnz .element_type_loop


.ret:

	ret			; return

.Kel:
	times 1152 db 0	; initialize 12x12 matrix of 0.0

.Kel_trans:
	times 1152 db 0	; initialize 12x12 matrix of 0.0

%endif
