%ifndef QUADRATURE
%define QUADRATURE

quadrature:
; double {xmm0} quadrature(void* {rdi}, ulong {rsi}, double {xmm0}, double {xmm1});
; Estimates the definite integral of the function at address {rdi} between {xmm0}<=x<={xmm1} 
; using Gaussian quadrature of order {rsi}. Area returned in {xmm0}.
; Only orders 1-5 supported.
; Function of interest should take independent variable and returns dependend variable in {xmm0}.

	push rsi
	push rax
	push rdx
	sub rsp,48
	movdqu [rsp+0],xmm2
	movdqu [rsp+16],xmm3
	movdqu [rsp+32],xmm4

	mov rax,rsi
	xor rdx,rdx
	dec rax
	jz .no_preloop
.preloop:
	add rdx,rax
	dec rax
	jnz .preloop
.no_preloop:
	shl rdx,4
	add rdx,.points_n_weights ; {rdx} points to points
	mov rax,rsi
	shl rax,3
	add rax,rdx		; {rax} points to weights

	; {xmm2} multiplies pt to adjust range
	movsd xmm2,xmm1
	subsd xmm2,xmm0
	mulsd xmm2,[.half]

	; {xmm3} adds to product to adjust range
	movsd xmm3,xmm0
	addsd xmm3,xmm1
	mulsd xmm3,[.half]

	; integral becomes evaluation of sum(Wi*f({xmm2}*Pi+{xmm3}))

	pxor xmm4,xmm4
		
.loop:
	movsd xmm0,[rdx]
	mulsd xmm0,xmm2
	addsd xmm0,xmm3
	call rdi	
	mulsd xmm0,[rax] ; might not work btw
	addsd xmm4,xmm0

	add rdx,8
	add rax,8
	dec rsi
	jnz .loop

	mulsd xmm4,xmm2

	movsd xmm0,xmm4
	movdqu xmm2,[rsp+0]
	movdqu xmm3,[rsp+16]
	movdqu xmm4,[rsp+32]
	add rsp,48

	pop rdx
	pop rax
	pop rsi

	ret		; return

; order 1: offset 0 (0)*8
; order 2: offset 16 (0+2)*8
; order 3: offset 48 (0+2+4)*8
; order 4: offset 96 (0+2+4+6)*8
; order 5: offset 160 (0+2+4+6+8)*8

.points_n_weights:
; order 1
.o1_pts:
	dq 0.0
.o1_weights:
	dq 2.0
; order 2 
.o2_pts:
	dq -0.577350269189626
	dq 0.577350269189626
.o2_weights:
	dq 1.0
	dq 1.0
; order 3
.o3_pts:
	dq -0.774596669241483
	dq 0.0
	dq 0.774596669241483
.o3_weights:
	dq 0.5555555555555556
	dq 0.8888888888888889
	dq 0.5555555555555556
; order 4
.o4_pts:
	dq -0.861136311594053
	dq -0.339981043584856
	dq 0.339981043584856
	dq 0.861136311594053
.o4_weights:
	dq 0.347854845137454
	dq 0.652145154862546
	dq 0.652145154862546
	dq 0.347854845137454
; order 5
.o5_pts:
	dq -0.906179845938664
	dq -0.538469310105683
	dq 0.0
	dq 0.538469310105683
	dq 0.906179845938664
.o5_weights:
	dq 0.236926885056189
	dq 0.478628670499366
	dq 0.568888888888889
	dq 0.478628670499366
	dq 0.236926885056189
.half:
	dq 0.5
%endif
