%ifndef COSINE_SINE_CORDIC_INT
%define COSINE_SINE_CORDIC_INT

; double {xmm0}, double {xmm1} cosine_sine_cordic_int(double {xmm0}, uint {rdi});
;	Returns approximation of cosine({xmm0}) & sine({xmm0}) in {xmm0} & {xmm1}
;	respectively, using CORDIC integer approximation with {rdi} iterations
;	(1-60).

align 64
cosine_sine_cordic_int:

	push rsi
	push rax
	push rbx
	push rcx
	push rdx
	push r8
	push r9
	push r10
	push r11

	movsd xmm1,xmm0
	mulsd xmm1,[.recip_two_pi]
	;roundsd xmm1,xmm1,0b11		; truncate xmm1 to integer
	roundsd xmm1,xmm1,0b01		; round down
	mulsd xmm1,[.two_pi]		; xmm1 is the closest multiple of 2pi
					; of lower absolute value
	subsd xmm0,xmm1			; xmm0 is now within [-2pi,2pi]
	
.in_range: ; needs to be between 0 and tau
	
	; convert {xmm0} to CAU (2^(60+2)) fraction
	mulsd xmm0,[.CAU_SCALE]
	cvtsd2si rax,xmm0	

	mov rbx,1
	shl rbx,60	; cordicBase

	mov rcx,rbx
	shl rcx,1	; quad2Boundary

	mov r8,rcx
	shl r8,1	; max

	mov rdx,rcx
	add rdx,rbx	; quad3Boundary

	cmp rax,rdx
	jle .notQuad4
	sub rax,r8
	neg rax
	mov r8,4
	jmp .alg
.notQuad4:
	cmp rax,rcx
	jle .notQuad3
	mov r8,3
	sub rax,rcx
	jmp .alg
.notQuad3:
	cmp rax,rbx
	jle .notQuad2	
	mov r8,2
	sub rax,rcx
	neg rax
	jmp .alg
.notQuad2:
	mov r8,1
.alg:

	neg rax		; z

	mov rbx,rdi
	dec rbx
	shl rbx,3
	add rbx,.xinit

	mov rbx,[rbx] ; x val
	xor rdx,rdx	; y val

	mov rcx,0
	mov rsi,.atan_table
.loop:
	test rax,rax
	js .ccw_rotation
.cw_rotation:
	sub rax,[rsi]
	mov r9,rbx
	mov r10,rdx
	sar r9,cl
	sar r10,cl 
	add rbx,r10
	sub rdx,r9
	jmp .next
.ccw_rotation:
	add rax,[rsi]
	mov r9,rbx
	mov r10,rdx
	sar r9,cl
	sar r10,cl 
	sub rbx,r10
	add rdx,r9
.next:

	inc rcx
	add rsi,8
	cmp rcx,rdi
	jl .loop

	cmp r8,1
	je .no_neg_x
	cmp r8,4
	je .no_neg_x
.neg_x:
	neg rbx
.no_neg_x:
	cmp r8,1
	je .no_neg_y
	cmp r8,2
	je .no_neg_y
.neg_y:
	neg rdx
.no_neg_y:

	cvtsi2sd xmm0,rbx
	cvtsi2sd xmm1,rdx
	mulsd xmm0,[.OUT_SCALE]
	mulsd xmm1,[.OUT_SCALE]

.ret:
	pop r11
	pop r10
	pop r9
	pop r8
	pop rdx
	pop rcx
	pop rbx
	pop rax
	pop rsi

	ret 

align 8

.CAU_SCALE:
	dq 0x43a45f306dc9c883

.OUT_SCALE:
	dq 0x3c30000000000000

.xinit:
       	dq 815238614083298816 ; 1
        dq 729171583589189504 ; 2
        dq 707400343138147072 ; 3
        dq 701937710475640576 ; 4
        dq 700570741874588288 ; 5
        dq 700228916656934784 ; 6
        dq 700143455142409344 ; 7
        dq 700122089437857664 ; 8
        dq 700116747991345280 ; 9
        dq 700115412628443648 ; 10
        dq 700115078787638528 ; 11
        dq 700114995327432448 ; 12
        dq 700114974462380416 ; 13
        dq 700114969246117504 ; 14
        dq 700114967942051840 ; 15
        dq 700114967616035328 ; 16
        dq 700114967534531200 ; 17
        dq 700114967514155264 ; 18
        dq 700114967509061120 ; 19
        dq 700114967507787648 ; 20
        dq 700114967507469312 ; 21
        dq 700114967507389824 ; 22
        dq 700114967507369856 ; 23
        dq 700114967507364864 ; 24
        dq 700114967507363584 ; 25
        dq 700114967507363328 ; 26
        dq 700114967507363200 ; 27
        dq 700114967507363200 ; 28
        dq 700114967507363200 ; 29
        dq 700114967507363200 ; 30
        dq 700114967507363200 ; 31
        dq 700114967507363200 ; 32
        dq 700114967507363200 ; 33
        dq 700114967507363200 ; 34
        dq 700114967507363200 ; 35
        dq 700114967507363200 ; 36
        dq 700114967507363200 ; 37
        dq 700114967507363200 ; 38
        dq 700114967507363200 ; 39
        dq 700114967507363200 ; 40
        dq 700114967507363200 ; 41
        dq 700114967507363200 ; 42
        dq 700114967507363200 ; 43
        dq 700114967507363200 ; 44
        dq 700114967507363200 ; 45
        dq 700114967507363200 ; 46
        dq 700114967507363200 ; 47
        dq 700114967507363200 ; 48
        dq 700114967507363200 ; 49
        dq 700114967507363200 ; 50
        dq 700114967507363200 ; 51
        dq 700114967507363200 ; 52
        dq 700114967507363200 ; 53
        dq 700114967507363200 ; 54
        dq 700114967507363200 ; 55
        dq 700114967507363200 ; 56
        dq 700114967507363200 ; 57
        dq 700114967507363200 ; 58
        dq 700114967507363200 ; 59
        dq 700114967507363200 ; 60

.two_pi:	; ~6.3
	dq 0x401921FB54442D18

.recip_two_pi:	; 1/6.3
	dq 0x3FC45F306DC9C883

.atan_table:
	dq 576460752303423488
	dq 340304653033718272
	dq 179807632645220256
	dq 91273161881380496
	dq 45813697873323712
	dq 22929182573009056
	dq 11467389120678284
	dq 5734044481687724
	dq 2867065987018959
	dq 1433538461969103
	dq 716769914547871
	dq 358385042719534
	dq 179192532040473
	dq 89596267355325
	dq 44798133844549
	dq 22399066943135
	dq 11199533474176
	dq 5599766737414
	dq 2799883368748
	dq 1399941684379
	dq 699970842191
	dq 349985421096
	dq 174992710548
	dq 87496355274
	dq 43748177637
	dq 21874088819
	dq 10937044410
	dq 5468522205
	dq 2734261103
	dq 1367130552
	dq 683565276
	dq 341782638
	dq 170891319
	dq 85445660
	dq 42722830
	dq 21361415
	dq 10680708
	dq 5340354
	dq 2670177
	dq 1335089
	dq 667545
	dq 333773
	dq 166887
	dq 83444
	dq 41722
	dq 20861
	dq 10431
	dq 5216
	dq 2608
	dq 1304
	dq 652
	dq 326
	dq 163
	dq 82
	dq 41
	dq 21
	dq 11
	dq 6
	dq 3
	dq 2

%endif
