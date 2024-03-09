%ifndef TRAPEZOIDAL_METHOD
%define TRAPEZOIDAL_METHOD

trapezoidal_method:
; double {xmm0} trapezoidal_method(void* {rdi}, double {xmm0}, double {xmm1}, double {xmm2});
; Estimates the definite integral of the function at address {rdi} between {xmm0}<=x<={xmm1} using a trapezoidal method and step size in {xmm2}. Area returned in {xmm0}.
; Function of interest should take independent variable and returns dependend variable in {xmm0}.

	sub rsp,48
	movdqu [rsp+0],xmm3
	movdqu [rsp+16],xmm4
	movdqu [rsp+32],xmm5

	movsd xmm3,xmm0		; x val track
	pxor xmm4,xmm4		; track sum

	call rdi
	movsd xmm5,xmm0
	addsd xmm3,xmm2

.loop:
	movsd xmm0,xmm3
	call rdi
	addsd xmm0,xmm5
	mulsd xmm0,[.half]
	mulsd xmm0,xmm2
	addsd xmm4,xmm0

	movsd xmm5,xmm0;;;;fix
	addsd xmm3,xmm2
	comisd xmm3,xmm1
	jbe .loop

.ret:
	movdqu xmm3,[rsp+0]
	movdqu xmm4,[rsp+16]
	add rsp,48

	ret		; return

.half:
	dq 0.50
%endif
