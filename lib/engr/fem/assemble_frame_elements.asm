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
	
	ret			; return

%endif
