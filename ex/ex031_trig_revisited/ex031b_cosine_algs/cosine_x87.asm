%ifndef COSINE_X87
%define COSINE_X87

; double {xmm0} cosine_x87(double {xmm0});
;	Returns approximation of cosine({xmm0}) in {xmm0} using the FPU.

align 64
cosine_x87:

	movsd [.value],xmm0
	fld qword [.value]
	fcos
	fstp qword [.value]
	movsd xmm0,[.value]
	ret

.value:
	dq 0.0

%endif

