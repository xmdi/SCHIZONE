%ifndef TRIANGLE_NORMAL
%define TRIANGLE_NORMAL

triangle_normal:
; void triangle_normal(double* {rdi}, double* {rsi}, double* {rdx}, 
;			double* {rcx});
;	Computes the normal of the triangle (anticlockwise vertex numbering,
;	AKA right hand rule) with double-precision (x,y,z) vertex position
;	located at {rsi}, {rdx}, and {rcx} respectively (eg, vertex A position
;	stored in 24 bytes at {rsi}, etc.). Returns the normal direction in 
;	the 24 bytes at {rdi}.

	sub rsp,128
	movdqu [rsp+0],xmm0
	movdqu [rsp+16],xmm1
	movdqu [rsp+32],xmm2
	movdqu [rsp+48],xmm3
	movdqu [rsp+64],xmm4
	movdqu [rsp+80],xmm5
	movdqu [rsp+96],xmm6
	movdqu [rsp+112],xmm7

	; Bx-Ax
	movsd xmm0,[rdx]
	subsd xmm0,[rsi]
	; By-Ay
	movsd xmm1,[rdx+8]
	subsd xmm1,[rsi+8]
	; Bz-Az
	movsd xmm2,[rdx+16]
	subsd xmm2,[rsi+16]
	; Cx-Ax
	movsd xmm3,[rcx]
	subsd xmm3,[rsi]
	; Cy-Ay
	movsd xmm4,[rcx+8]
	subsd xmm4,[rsi+8]
	; Cz-Az
	movsd xmm5,[rcx+16]
	subsd xmm5,[rsi+16]

	; x-component of normal
	movsd xmm6,xmm1
	mulsd xmm6,xmm5
	movsd xmm7,xmm2
	mulsd xmm7,xmm4
	subsd xmm6,xmm7
	movsd [rdi+0],xmm6
	; y-component of normal
	movsd xmm6,xmm2
	mulsd xmm6,xmm3
	movsd xmm7,xmm0
	mulsd xmm7,xmm5
	subsd xmm6,xmm7
	movsd [rdi+8],xmm6
	; z-component of normal
	movsd xmm6,xmm0
	mulsd xmm6,xmm4
	movsd xmm7,xmm1
	mulsd xmm7,xmm3
	subsd xmm6,xmm7
	movsd [rdi+16],xmm6

	movdqu xmm0,[rsp+0]
	movdqu xmm1,[rsp+16]
	movdqu xmm2,[rsp+32]
	movdqu xmm3,[rsp+48]	
	movdqu xmm4,[rsp+64]
	movdqu xmm5,[rsp+80]
	movdqu xmm6,[rsp+96]
	movdqu xmm7,[rsp+112]
	add rsp,128

	ret			; return

%endif
