%ifndef COSINE_LOOKUP
%define COSINE_LOOKUP

; double {xmm0} cosine_lookup(double {xmm0});
;	Returns approximation of sine({xmm0}) in {xmm0} using coarse lookup
;	table.

align 64
cosine_lookup:

	push rax
	push rbx
	sub rsp,32
	movdqu [rsp+0],xmm1
	movdqu [rsp+16],xmm2

	xor rax,rax
	xor rbx,rbx	; negate flag

;	pxor xmm1,xmm1
;	comisd xmm0,xmm1
;	jae .no_negate
	pslld xmm0,1
	psrld xmm0,1
;	mov rbx,1

	movsd xmm1,xmm0
	mulsd xmm1,[.recip_two_pi]
	roundsd xmm1,xmm1,0b11		; truncate xmm8 to integer
	mulsd xmm1,[.two_pi]		; xmm8 is the closest multiple of 2pi
					; of lower absolute value
	subsd xmm0,xmm1			; xmm0 is now within [0,2pi]

	movsd xmm1,[.pi]
	comisd xmm0,xmm1
	jbe .reduced
	movsd xmm1,[.two_pi]
	subsd xmm1,xmm0
	movsd xmm0,xmm1
.reduced:				; xmm0 is now within [0,pi]

	movsd xmm1,[.half_pi]
	comisd xmm0,xmm1
	jbe .reduced2
	movsd xmm1,[.pi]
	subsd xmm1,xmm0
	movsd xmm0,xmm1
	mov rbx,1

.reduced2:				; xmm0 is now within [0,pi/2]

;	debug_reg_f xmm0
;	debug_exit 2

	cvtsd2ss xmm0,xmm0
	mulss xmm0,[.scalar]
	cvtss2si eax,xmm0

	add eax,3
	and eax,0xFFFFFFFC

	movss xmm0,[eax+.lookup_table]

	cvtss2sd xmm0,xmm0

	test rbx,rbx
	jz .no_neg
	mulsd xmm0,[.neg]

.no_neg:

	movdqu xmm1,[rsp+0]
	movdqu xmm2,[rsp+16]
	add rsp,32

	pop rbx
	pop rax

	ret 

align 8

.neg:		; -1
	dq 0xBFF0000000000000

.half_pi:
	dq 0x3FF921FB54442D18

.pi:	; ~3.1
	dq 0x400921FB54442D18

.two_pi:	; ~6.3
	dq 0x401921FB54442D18

.recip_two_pi:	; 1/6.3
	dq 0x3FC45F306DC9C883

.scalar:	; 800/pi
	dd 0x437ea5dd

.lookup_table:
	dd 0x3f800000
	dd 0x3f7ff7ea
	dd 0x3f7fdfa9
	dd 0x3f7fb73f
	dd 0x3f7f7eae
	dd 0x3f7f35f9
	dd 0x3f7edd26
	dd 0x3f7e743a
	dd 0x3f7dfb3b
	dd 0x3f7d7231
	dd 0x3f7cd925
	dd 0x3f7c3020
	dd 0x3f7b772d
	dd 0x3f7aae59
	dd 0x3f79d5ae
	dd 0x3f78ed3c
	dd 0x3f77f511
	dd 0x3f76ed3c
	dd 0x3f75d5cf
	dd 0x3f74aeda
	dd 0x3f737871
	dd 0x3f7232a6
	dd 0x3f70dd90
	dd 0x3f6f7943
	dd 0x3f6e05d5
	dd 0x3f6c835e
	dd 0x3f6af1f8
	dd 0x3f6951ba
	dd 0x3f67a2bf
	dd 0x3f65e523
	dd 0x3f641901
	dd 0x3f623e77
	dd 0x3f6055a2
	dd 0x3f5e5ea3
	dd 0x3f5c5997
	dd 0x3f5a46a0
	dd 0x3f5825e0
	dd 0x3f55f779
	dd 0x3f53bb8d
	dd 0x3f517243
	dd 0x3f4f1bbd
	dd 0x3f4cb822
	dd 0x3f4a4799
	dd 0x3f47ca4a
	dd 0x3f45405b
	dd 0x3f42a9f7
	dd 0x3f400747
	dd 0x3f3d5877
	dd 0x3f3a9db0
	dd 0x3f37d720
	dd 0x3f3504f3
	dd 0x3f322757
	dd 0x3f2f3e7b
	dd 0x3f2c4a8c
	dd 0x3f294bbc
	dd 0x3f26423a
	dd 0x3f232e38
	dd 0x3f200fe7
	dd 0x3f1ce77a
	dd 0x3f19b524
	dd 0x3f167918
	dd 0x3f13338b
	dd 0x3f0fe4b2
	dd 0x3f0c8cc2
	dd 0x3f092bf2
	dd 0x3f05c277
	dd 0x3f02508a
	dd 0x3efdacc2
	dd 0x3ef6a86b
	dd 0x3eef947f
	dd 0x3ee87171
	dd 0x3ee13fb5
	dd 0x3ed9ffbe
	dd 0x3ed2b203
	dd 0x3ecb56f8
	dd 0x3ec3ef15
	dd 0x3ebc7ad2
	dd 0x3eb4faa8
	dd 0x3ead6f0f
	dd 0x3ea5d881
	dd 0x3e9e377a
	dd 0x3e968c74
	dd 0x3e8ed7ec
	dd 0x3e871a5e
	dd 0x3e7ea890
	dd 0x3e6f0c4d
	dd 0x3e5f60f1
	dd 0x3e4fa779
	dd 0x3e3fe0e3
	dd 0x3e300e2f
	dd 0x3e20305b
	dd 0x3e10486a
	dd 0x3e00575b
	dd 0x3de0bc62
	dd 0x3dc0bbdc
	dd 0x3da0af2a
	dd 0x3d809851
	dd 0x3d40f2b2
	dd 0x3d00a891
	dd 0x3c80aca2
	dd 0x248d3132

%endif
