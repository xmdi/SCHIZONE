%ifndef SET_TRIANGLE_DEPTH
%define SET_TRIANGLE_DEPTH

; dependency
%include "lib/io/print_int_h.asm"
%include "lib/io/print_float.asm"
%include "lib/io/print_array_float.asm"
%include "lib/io/bitmap/set_pixel.asm"

set_triangle_depth:
; void set_triangle_depth(void* {rdi}, long*/long {rsi}, int {edx}, int {ecx},
;		 double* {r8}, bool {r9}, single* {r10})
;	Fills triangle with vertices described by 9 double-precision floats
;	starting at {r8} (projected x, projected y, projected depth)
;	in ARGB data array starting at {rdi} for an {edx}x{ecx} (WxH) image. 
;	{r9} contains color interpolation flag. If low bit of {r9} is high, 
;	{rsi} points to 3x1 ARGB color array (32 bpp). If low bit of {r9} 
;	is low, {rsi} contains triangle fill color (32 bpp). Pointer to 
;	single-precision depth buffer at {r10} (4*{ecx}*{edx} bytes).

	push rax
	push rbx
	push rbp
	push rsi
	push r8
	push r9
	push r15
	sub rsp,256
	movdqu [rsp+0],xmm0
	movdqu [rsp+16],xmm1
	movdqu [rsp+32],xmm2
	movdqu [rsp+48],xmm3
	movdqu [rsp+64],xmm4
	movdqu [rsp+80],xmm5
	movdqu [rsp+96],xmm6
	movdqu [rsp+112],xmm7
	movdqu [rsp+128],xmm8
	movdqu [rsp+144],xmm9
	movdqu [rsp+160],xmm10
	movdqu [rsp+176],xmm11
	movdqu [rsp+192],xmm12
	movdqu [rsp+208],xmm13
	movdqu [rsp+224],xmm14
	movdqu [rsp+240],xmm15

	mov r15,rsi

	movsd xmm12,[r8+0]	; min vtx 1 x
	minsd xmm12,[r8+24]	; min vtx 2 x
	minsd xmm12,[r8+48]	; min vtx 3 x
	roundsd xmm12,xmm12,0b0001
	movsd xmm13,[r8+0]	; max vtx 1 x
	maxsd xmm13,[r8+24]	; max vtx 2 x
	maxsd xmm13,[r8+48]	; max vtx 3 x
	roundsd xmm13,xmm13,0b0010
	movsd xmm14,[r8+8]	; min vtx 1 y
	minsd xmm14,[r8+32]	; min vtx 2 y
	minsd xmm14,[r8+56]	; min vtx 3 y
	roundsd xmm14,xmm14,0b0001
	movsd xmm15,[r8+8]	; max vtx 1 y
	maxsd xmm15,[r8+32]	; max vtx 2 y
	maxsd xmm15,[r8+56]	; max vtx 3 y
	roundsd xmm15,xmm15,0b0010

%if 0

	push rdi
	push rsi
	push rdx
	mov rdi,SYS_STDOUT
	mov rsi,5
	movsd xmm0,xmm12
	call print_float	
	mov rsi,.grammar+4
	mov rdx,1
	call print_chars
	mov rsi,5
	movsd xmm0,xmm13
	call print_float	
	mov rsi,.grammar+4
	mov rdx,1
	call print_chars
	mov rsi,5
	movsd xmm0,xmm14
	call print_float	
	mov rsi,.grammar+4
	mov rdx,1
	call print_chars
	mov rsi,5
	movsd xmm0,xmm15
	call print_float	
	mov rsi,.grammar+4
	mov rdx,1
	call print_chars
	call print_buffer_flush
	pop r8
	pop rcx
	pop rdx
	pop rsi
	pop rdi
%endif

	; check if triangle is off the screen
	pxor xmm0,xmm0	
	comisd xmm15,xmm0 ; max y
	jb .off_screen
	comisd xmm13,xmm0 ; max x
	jb .off_screen
	cvtsi2sd xmm0,[framebuffer_init.framebuffer_width]
	comisd xmm12,xmm0 ; min x
	ja .off_screen
	cvtsi2sd xmm0,[framebuffer_init.framebuffer_height]
	comisd xmm14,xmm0 ; min y
	ja .off_screen

	; screw parallel stuff
	; populate vtx_to_vtx arrays
;	movupd xmm0,[r8+24]
;	subpd xmm0,[r8+0]
;	movupd [.vtx0_to_vtx1],xmm0
;	movupd xmm0,[r8+48]
;	subpd xmm0,[r8+24]
;	movupd [.vtx1_to_vtx2],xmm0
;	movupd xmm0,[r8+0]
;	subpd xmm0,[r8+48]
;	movupd [.vtx2_to_vtx0],xmm0

	movsd xmm0,[r8+24]
	subsd xmm0,[r8+0]
	movsd [.vtx0_to_vtx1+0],xmm0
	movsd xmm0,[r8+32]
	subsd xmm0,[r8+8]
	movsd [.vtx0_to_vtx1+8],xmm0

	movsd xmm0,[r8+48]
	subsd xmm0,[r8+24]
	movsd [.vtx1_to_vtx2+0],xmm0
	movsd xmm0,[r8+56]
	subsd xmm0,[r8+32]
	movsd [.vtx1_to_vtx2+8],xmm0

	movsd xmm0,[r8+0]
	subsd xmm0,[r8+48]
	movsd [.vtx2_to_vtx0+0],xmm0
	movsd xmm0,[r8+8]
	subsd xmm0,[r8+56]
	movsd [.vtx2_to_vtx0+8],xmm0

%if 0
	push rdi
	push rsi
	push rdx
	push rcx
	push r8
	push r9
	push r10
	mov rdi,SYS_STDOUT
	mov rsi,.vtx_to_pt
	mov rdx,4
	mov rcx,2
	xor r8,r8
	mov r9,print_float
	mov r10,8
	call print_array_float
	call print_buffer_flush
	pop r10
	pop r9
	pop r8
	pop rcx
	pop rdx
	pop rsi
	pop rdi
%endif

	pxor xmm9,xmm9
	movsd xmm11,xmm14

;	push rdi
;	push rsi
;	push rdx
;	mov rdi,SYS_STDOUT
;	mov rsi,.vtx_computed
;	mov rdx,10
;	call print_chars
;	call print_buffer_flush
;	pop rdx
;	pop rsi
;	pop rdi

	; pt to check/plot at ({xmm10},{xmm11}) ; could be ints and constantly converted via cvtsi2sd

.rect_loop_y:

	movsd xmm10,xmm12

.rect_loop_x:

	; check edges	

%if 0
	push rdi
	push rsi
	push rdx
	mov rdi,SYS_STDOUT
	
	; vtx 0
	mov rsi,.cp+1
	mov rdx,1
	call print_chars

	mov rsi,5
	movsd xmm0,[r8+0]
	call print_float

	mov rsi,.cp+2
	mov rdx,1
	call print_chars

	mov rsi,5
	movsd xmm0,[r8+8]
	call print_float

	mov rsi,.cp+3
	mov rdx,5
	call print_chars

	; Pt
	mov rsi,.cp+1
	mov rdx,1
	call print_chars

	mov rsi,5
	movsd xmm0,xmm10
	call print_float

	mov rsi,.cp+2
	mov rdx,1
	call print_chars

	mov rsi,5
	movsd xmm0,xmm11
	call print_float

	mov rsi,.cp+3
	mov rdx,1
	call print_chars

	mov rsi,.cp+8
	mov rdx,1
	call print_chars

	; vector vtx0->Pt
	mov rsi,.cp+1
	mov rdx,1
	call print_chars

	mov rsi,5
	movsd xmm0,xmm10
	subsd xmm0,[r8+0]
	call print_float

	mov rsi,.cp+2
	mov rdx,1
	call print_chars

	mov rsi,5
	movsd xmm0,xmm11
	subsd xmm0,[r8+8]
	call print_float

	mov rsi,.cp+3
	mov rdx,1
	call print_chars

	; newline
	mov rsi,.cp+9
	mov rdx,1
	call print_chars

	; vtx 0 to vtx1
	mov rsi,.cp+1
	mov rdx,1
	call print_chars

	mov rsi,5
	movsd xmm0,[.vtx0_to_vtx1+0]
	call print_float

	mov rsi,.cp+2
	mov rdx,1
	call print_chars

	mov rsi,5
	movsd xmm0,[.vtx0_to_vtx1+8]
	call print_float

	mov rsi,.cp+3
	mov rdx,1
	call print_chars

	; newline
	mov rsi,.cp+9
	mov rdx,1
	call print_chars


	; cross product result
	mov rsi,.cp+8
	mov rdx,1
	call print_chars


	movsd xmm1,xmm10
	subsd xmm1,[r8+0] ; todo x and y can be parallelized here
	movsd xmm0,xmm11
	subsd xmm0,[r8+8]
	; vtx1-vtx0
	movsd xmm3,[.vtx0_to_vtx1+0]
	movsd xmm2,[.vtx0_to_vtx1+8]
;	movsd xmm3,[r8+24]
;	subsd xmm3,[r8+0]
;	movsd xmm2,[r8+32]
;	subsd xmm2,[r8+8]
	mulsd xmm1,xmm2
	mulsd xmm0,xmm3
	subsd xmm1,xmm0

	movsd xmm0,xmm1
	mov rsi,5
	call print_float

	; newline
	mov rsi,.cp+9
	mov rdx,1
	call print_chars
	
	pop rdx
	pop rsi
	pop rdi

;	db `X(,) to =\n`

%endif

	; cross product of vtx0->pt and vtx0->vtx1	
	; pt-vtx0
	movsd xmm1,xmm10
	subsd xmm1,[r8+0] ; todo x and y can be parallelized here
	movsd xmm0,xmm11
	subsd xmm0,[r8+8]
	; vtx1-vtx0
	movsd xmm3,[.vtx0_to_vtx1+0]
	movsd xmm2,[.vtx0_to_vtx1+8]
;	movsd xmm3,[r8+24]
;	subsd xmm3,[r8+0]
;	movsd xmm2,[r8+32]
;	subsd xmm2,[r8+8]
	mulsd xmm1,xmm2
	mulsd xmm0,xmm3
	subsd xmm1,xmm0
	comisd xmm1,xmm9
	ja .point_no_good ; might need to be ja
	movsd xmm4,xmm1	 	; {xmm4} contains barycentric coefficient w

	; cross product of vtx1->pt and vtx1->vtx2	
	; pt-vtx1
	movsd xmm1,xmm10
	subsd xmm1,[r8+24] ; todo x and y can be parallelized here
	movsd xmm0,xmm11
	subsd xmm0,[r8+32]
	; vtx2-vtx1	
	movsd xmm3,[.vtx1_to_vtx2+0]
	movsd xmm2,[.vtx1_to_vtx2+8]
;	movsd xmm3,[r8+48]
;	subsd xmm3,[r8+24]
;	movsd xmm2,[r8+56]
;	subsd xmm2,[r8+32]
	mulsd xmm1,xmm2
	mulsd xmm0,xmm3
	subsd xmm1,xmm0
	comisd xmm1,xmm9
	ja .point_no_good ; might need to be ja
	movsd xmm5,xmm1	 	; {xmm5} contains barycentric coefficient u

	; cross product of vtx2->pt and vtx2->vtx0	
	; pt-vtx2
	movsd xmm1,xmm10
	subsd xmm1,[r8+48] ; todo x and y can be parallelized here
	movsd xmm0,xmm11
	subsd xmm0,[r8+56]
	; vtx0-vtx2p	
	movsd xmm3,[.vtx2_to_vtx0+0]
	movsd xmm2,[.vtx2_to_vtx0+8]
;	movsd xmm3,[r8+0]
;	subsd xmm3,[r8+48]
;	movsd xmm2,[r8+8]
;	subsd xmm2,[r8+56]
	mulsd xmm1,xmm2
	mulsd xmm0,xmm3
	subsd xmm1,xmm0
	comisd xmm1,xmm9
	ja .point_no_good ; might need to be ja
	movsd xmm6,xmm1	 	; {xmm6} contains barycentric coefficient v

%if 0
	push rdi
	push rsi
	push rdx
	mov rdi,SYS_STDOUT
	mov rsi,.newline
	mov rdx,1
	call print_chars
	movsd xmm0,xmm6
	mov rsi,5
	call print_float	
	mov rsi,.newline
	mov rdx,1
	call print_chars
	
	call print_buffer_flush
	call exit
%endif


.point_in_triangle:
	;	barycentric coordinates for point in triangle at
	;		( {xmm4} , {xmm5} , {xmm6} )

	; compute depth at this point first
	; {xmm4}*[r8+16] + {xmm5}*[r8+40] + {xmm6}*[r8+64]

	movsd xmm0,xmm4
	movsd xmm1,xmm5
	movsd xmm2,xmm6
	mulsd xmm0,[r8+16]	
	mulsd xmm1,[r8+40]	
	mulsd xmm2,[r8+64]	
	addsd xmm0,xmm1
	addsd xmm0,xmm2
	; depth of pixel of interest in {xmm0} (double precision)

%if 0
	push rdi
	push rsi
	push rdx
	mov rdi,SYS_STDOUT
	mov rsi,.newline
	mov rdx,1
	call print_chars
	movsd xmm0,xmm6
	mov rsi,5
	call print_float	
	mov rsi,.newline
	mov rdx,1
	call print_chars
	
	call print_buffer_flush
;	call exit

%endif

	cvtsd2ss xmm0,xmm0 ; might not work LOL

	cvtsd2si rax,xmm10 ; x coord
	cvtsd2si rbx,xmm11 ; y coord

	mov rbp,rbx
	imul rbp,rdx
	add rbp,rax
	shl rbp,2 ; {rbp} contains byte number for pixel of interest
	add rbp,r10	; {rbp} points to depth for pixel of interest
	movss xmm1,[rbp]

	comiss xmm0,xmm1
	jae .too_deep_to_put_pixel
	
	; overwrite depth
	movss [rbp],xmm0

	; compute color at this point
	cmp r9,0 ; TODO should be a test instruction tbh, not cmp
	je .color_computed

%if 0
	push rdi
	push rsi
	push rdx

	mov rdi,SYS_STDOUT
	mov rsi,10
	cvtss2sd xmm0,xmm0
	call print_float

	call print_buffer_flush
;	call exit

	pop rdx
	pop rsi
	pop rdi

%endif



	; {xmm4}*[r8+16] + {xmm5}*[r8+40] + {xmm6}*[r8+64]
	cvtsi2sd xmm0,[r15+0]
	cvtsi2sd xmm1,[r15+8]
	cvtsi2sd xmm2,[r15+16]
	mulsd xmm0,xmm4
	mulsd xmm1,xmm5	
	mulsd xmm2,xmm6
	addsd xmm0,xmm1
	addsd xmm0,xmm2
	; color of pixel of interest in {xmm0} (double precision)
	cvtsd2si rsi,xmm0 ; and now in {rsi}

.color_computed:
	; put the pixel

	push r8
	push r9
	mov r8,rax
	mov r9,rbx
	call set_pixel
	pop r9
	pop r8

%if 0
	push rdi
	push rsi

	mov rsi,rcx	
	mov rdi,SYS_STDOUT
	call print_int_d
	call print_buffer_flush
	call exit


	pop rsi
	pop rdi
%endif

;	mov rdi,6
;	call exit

%if 0
	push rdi
	push rsi
	push rdx
	mov rdi,SYS_STDOUT
	mov rsi,.put_pixel
	mov rdx,10
	call print_chars
	mov rsi,[rsp+8]
	call print_int_h
	call print_buffer_flush

	mov rsi,.grammar
	mov rdx,4
	call print_chars
	mov rsi,rax
	call print_int_d
	mov rsi,.grammar+4
	mov rdx,1
	call print_chars
	mov rsi,rbx
	call print_int_d

	pop rdx
	pop rsi
	pop rdi

%endif

.too_deep_to_put_pixel:

.point_no_good:
	
	; pt to check/plot at ({xmm10},{xmm11}) ; could be ints and constantly converted via cvtsi2sd

%if 0
	push rdi
	push rsi
	push rdx
	
	mov rdi,SYS_STDOUT
	mov rsi,.no_put_pixel
	mov rdx,13
	call print_chars
	mov rsi,[rsp+8]
	call print_int_h
	call print_buffer_flush

	mov rsi,.grammar
	mov rdx,4
	call print_chars
	mov rsi,5
	movsd xmm0,xmm10
	call print_float
	mov rsi,.grammar+4
	mov rdx,1
	call print_chars
	movsd xmm0,xmm11
	mov rsi,5
	call print_float

	pop rdx
	pop rsi
	pop rdi
%endif

	addsd xmm10,[.one]
	comisd xmm10,xmm13
	jb .rect_loop_x


	addsd xmm11,[.one]
	comisd xmm11,xmm15
	jb .rect_loop_y

.off_screen:

	movdqu xmm0,[rsp+0]
	movdqu xmm1,[rsp+16]
	movdqu xmm2,[rsp+32]
	movdqu xmm3,[rsp+48]
	movdqu xmm4,[rsp+64]
	movdqu xmm5,[rsp+80]
	movdqu xmm6,[rsp+96]
	movdqu xmm7,[rsp+112]
	movdqu xmm8,[rsp+128]
	movdqu xmm9,[rsp+144]
	movdqu xmm10,[rsp+160]
	movdqu xmm11,[rsp+176]
	movdqu xmm12,[rsp+192]
	movdqu xmm13,[rsp+208]
	movdqu xmm14,[rsp+224]
	movdqu xmm15,[rsp+240]
	add rsp,256
	pop r15
	pop r9
	pop r8
	pop rsi
	pop rbp
	pop rbx
	pop rax

%if 0	
	push rdi
	push rsi
	push rdx
	mov rdi,SYS_STDOUT
	mov rsi,.got_out
	mov rdx,8
	call print_chars
	call print_buffer_flush

	pop rdx
	pop rsi
	pop rdi
%endif
	
	ret

.one:
	dq 1.0
.vtx_to_pt:
	times 2 dq 0.0
.vtx0_to_vtx1:
	times 2 dq 0.0
.vtx1_to_vtx2:
	times 2 dq 0.0
.vtx2_to_vtx0:
	times 2 dq 0.0

.vtx_computed:
	db `vecs comp\n`
.put_pixel:
	db `put pixel\n`
.got_out:
	db  `got out\n`
.in_tri:
	db  `in tri\n`
.check_dep:
	db  `check_dep\n`
.grammar:
	db ` at ,`
.no_put_pixel:
	db `no put pixel\n`
.newline:
	db `\n`
.cp:
	db `X(,) to =\n`
%endif
