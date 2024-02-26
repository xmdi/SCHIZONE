%ifndef ASSEMBLE_FRAME_ELEMENTS
%define ASSEMBLE_FRAME_ELEMENTS

; dependencies

assemble_frame_elements:
; void assemble_frame_elements(struct* {rdi});
; 	Assembles stiffness matrix at [{rdi}+40] for 3D frame element system
;	characterized by the 3D frame element system defined at {rdi}.

%if 0 ; 3D frame FEA system has this form:
.3D_FRAME:
		dq 0 ; number of nodes (6 DOF per node)
		dq 0 ; number of elements
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
	
	ret			; return

%endif
