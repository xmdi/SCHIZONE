%ifndef SINE_X87
%define SINE_X87

; double {xmm0} sine_x87(double {xmm0});
;	Returns approximation of sine({xmm0}) in {xmm0} using the FPU.

align 64
sine_x87:

	movsd [.value],xmm0
	fld qword [.value]
	fsin
	fstp qword [.value]
	movsd xmm0,[.value]
	ret

.value:
	dq 0.0

%endif

