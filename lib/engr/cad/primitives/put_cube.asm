%ifndef PUT_CUBE
%define PUT_CUBE

put_cube:
; void* {rax} put_cube(double {xmm0});
; 	Generates a cube primitive of side length {xmm0} and returns
;	the cube address in {rax}. NULL returned on error.

; sample cube primitive data structure
%if 0
.cube_primitive:
	dq 

%endif




.vertices:
	dq -0.5,-0.5,-0.5
	dq 0.5,-0.5,-0.5
	dq 0.5,0.5,-0.5
	dq -0.5,0.5,-0.5
	dq -0.5,-0.5,0.5
	dq 0.5,-0.5,0.5
	dq 0.5,0.5,0.5
	dq -0.5,0.5,0.5

.edges:
	dq 0,1,0x0
	dq 1,2,0x0
	dq 2,3,0x0
	dq 3,0,0x0
	dq 4,5,0x0
	dq 5,6,0x0
	dq 6,7,0x0
	dq 7,4,0x0

.faces:
	dq 0,2,1,0x0
	dq 0,3,2,0x0
	dq 4,5,6,0x0
	dq 4,6,7,0x0

	
%endif
