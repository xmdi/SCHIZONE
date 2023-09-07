%ifndef SCATTER_PLOT
%define SCATTER_PLOT

; dependencies
%include "lib/io/print_buffer_flush.asm"
%include "lib/io/print_chars.asm"
%include "lib/io/print_int_d.asm"
%include "lib/io/print_int_h_n_digits.asm"
%include "lib/io/print_string.asm"
%include "lib/io/print_float.asm"

; input data structures
%if 0
plot_structure:
	dq ; address of null-terminated title string {*+0}
	dq ; address of null-terminated x-label string {*+8}
	dq ; address of null-terminated y-label string {*+16}
	dq ; address of linked list for datasets {*+24}
	dw ; plot width (px) {*+32}
	dw ; plot height (px) {*+34}
	dw ; plot margins (px) {*+36}
	dq ; x-min (double) {*+38}
	dq ; x-max (double) {*+46}
	dq ; y-min (double) {*+54}
	dq ; y-max (double) {*+62}
	dw ; legend left x-coordinate (px) {*+70}
	dw ; legend top y-coordinate (px) {*+72}
	dw ; legend width (px) {*+74}
	dd ; #XXXXXX RGB background color {*+76}
	dd ; #XXXXXX RGB axis color {*+80}
	dd ; #XXXXXX RGB font color {*+84}
	db ; number of major x-ticks {*+88}
	db ; number of major y-ticks {*+89}
	db ; minor subdivisions per x-tick {*+90}
	db ; minor subdivisions per y-tick {*+91}
	db ; significant digits on x values {*+92}
	db ; significant digits on y values {*+93}
	db ; title font size (px) {*+94}
	db ; vertical margin below title (px) {*+95}
	db ; axis label font size (px) {*+96}
	db ; tick & legend label font size (px) {*+97}
	db ; horizontal margin right of y-tick labels (px) {*+98}
	db ; vertical margin above x-tick labels (px) {*+99}
	db ; grid major stroke thickness (px) {*+100}
	db ; grid minor stroke thickness (px) {*+101}
	db ; width for y-axis ticks (px) {*+102}
	db ; height for x-axis ticks (px) {*+103}
	db ; flags: {*+104}
		; bit 0 (LSB)	= show title?
		; bit 1		= show x-label?
		; bit 2		= show y-label?
		; bit 3		= draw grid?
		; bit 4		= show tick labels?
		; bit 5		= draw legend?

dataset_structure:
	dq ; address of next dataset in linked list {*+0}
	dq ; address of null-terminated label string {*+8}
	dq ; address of first x-coordinate {*+16}
	dw ; extra stride between x-coord elements {*+24}
	dq ; address of first y-coordinate {*+26}
	dw ; extra stride between y-coord elements {*+34}
	dd ; number of elements {*+36}
	dd ; #XXXXXX RGB marker color {*+40}
	dd ; #XXXXXX RGB line color {*+44}
	dd ; #XXXXXX RGB fill color {*+48}
	db ; marker size (px) {*+52}
	db ; line thickness (px) {*+53}
	db ; fill opacity (%) {*+54}
	db ; flags: {*+55}
		; bit 0 (LSB)	= point marker?
		; bit 1		= connecting lines?
		; bit 2		= dashed line? (bit 1 must be set)
		; bit 3		= fill?
		; bit 4		= include in legend?
		; bits 6-5	= 00 = no curves
		;		= 01 = quadratic bezier
		;		= 10 = cubic bezier
		;		= 11 = arc (TODO!)
%endif

scatter_plot:
; void scatter_plot(uint {rdi}, struct* {rsi});
;	Writes an SVG scatter plot described by the plot_structure struct at
;	address {rsi} to file descriptor {rdi}.
;	Note: Clears the PRINT_BUFFER (does not flush) at routine start.
	
	; pushes

	; save address of input structure in {rbx}
	mov rbx,rsi
	
	; start at beginning of PRINT_BUFFER
	mov [PRINT_BUFFER_LENGTH],0	

	; save flags in {r12}
	movzx r12, byte [rbx+104]

	; compute plot width and x-start coordinates
	movzx rsi, word [rbx+32] ; width
	movzx rcx, byte [rbx+36] ; margin
	mov r8,rcx
	shl rcx,1
	sub rsi,rcx
	movzx rcx, byte [rbx+102] ; y-tick width
	sub rsi,rcx
	add r8,rcx
	movzx rcx, byte [rbx+96] ; axis font size
	sub rsi,rcx
	add r8,rcx
	mov [.plot_width],rsi ; save plot width
	mov [.plot_x_start],r8 ; save x-start

	; compute plot height and y-start coordinates
	movzx rsi, word [rbx+34] ; height
	movzx rcx, byte [rbx+36] ; margin
	mov r8,rcx
	shl rcx,1
	sub rsi,rcx
	movzx rcx, byte [rbx+103] ; x-tick height
	sub rsi,rcx
	add r8,rcx
	movzx rcx, byte [rbx+96] ; axis font size
	sub rsi,rcx
	add r8,rcx
	movzx rcx, byte [rbx+94] ; title font size
	sub rsi,rcx
	add r8,rcx
	movzx rcx, byte [rbx+95] ; extra title margin
	sub rsi,rcx
	add r8,rcx
	mov [.plot_height],rsi ; save plot height
	mov [.plot_y_start],r8 ; save y-start

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; SVG HEADER ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	; write svg header
	mov rsi,.svg_header
	mov rdx,18
	call print_chars
	
	; viewbow width
	movzx rsi, word [rbx+32]
	call print_int_d

	; write space
	mov rsi,.svg_header+18
	mov rdx,1
	call print_chars

	; viewbox height
	movzx rsi, word [rbx+34]	
	call print_int_d

	; write more of svg header
	mov rsi,.svg_header+19
	mov rdx,44
	call print_chars

	; write width
	movzx rsi, word [rbx+32]
	call print_int_d

	; write more of svg_header
	mov rsi,.svg_header+63
	mov rdx,10
	call print_chars

	; write height
	movzx rsi, word [rbx+34]
	call print_int_d

	; write more of svg_header
	mov rsi,.svg_header+73
	mov rdx,27
	call print_chars

	; write background color
	movzx rsi, dword [rbx+76]
	mov rdx,6
	call print_int_h_n_digits

	; write end of svg header
	mov rsi,.svg_header+100
	mov rdx,3
	call print_chars

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; WRITE TITLE ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	; check if we want to write title
	test r12,1
	jz .x_label

	; write title start text
	mov rsi,.svg_text
	mov rdx,34
	call print_chars

	; write title font color
	movzx rsi, dword [rbx+84]
	mov rdx,6
	call print_int_h_n_digits

	; write more of title text
	mov rsi,.svg_text+34
	mov rdx,13
	call print_chars

	; write title font size
	movzx rsi, byte [rbx+94]
	call print_int_d

	; write more of title text
	mov rsi,.svg_text+47
	mov rdx,7
	call print_chars

	; write title x location
	movzx rsi, word [rbx+32]
	shr rsi,1	; divide by 2, we are centered on x
	call print_int_d

	; write more of title text
	mov rsi,.svg_text+54
	mov rdx,5
	call print_n_chars

	; write title y location
	movzx rsi, byte [rbx+94]
	add si, word [rbx+48]
	call print_int_d

	; write more of title text
	mov rsi,.svg_text+59
	mov rdx,2
	call print_chars

	; write actual title
	mov rsi,[rbx+0]
	call print_string

	; write end of title text
	mov rsi,.svg_text+61
	mov rdx,8
	call print_chars

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; WRITE X-LABEL ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.x_label:

	; check if we wanted to write an xlabel
	test r12,2
	jz .y_label
	
	; write xlabel text start
	mov rsi,.svg_text
	mov rdx,34
	call print_chars

	; write xlabel font color
	movzx rsi, dword [rbx+84]
	mov rdx,6
	call print_int_h_n_digits

	; write more of xlabel text
	mov rsi,.svg_text+34
	mov rdx,13
	call print_chars

	; write xlabel font size
	movzx rsi, byte [rbx+96]
	call print_int_d

	; write more of xlabel text
	mov rsi,.svg_text+47
	mov rdx,7
	call print_chars

	; write xlabel x location
	mov rsi,[.plot_width]
	shr rsi,1
	add rsi,[.plot_x_start]
	call print_int_d

	; write more of xlabel text
	mov rsi,.svg_text+54
	mov rdx,5
	call print_chars

	; write xlabel y location
	movzx rsi, word [rbx+34]
	sub si, word [rbx+48]
	call print_int_d

	; write more of xlabel text
	mov rsi,.svg_text+59
	mov rdx,2
	call print_chars

	; write actual xlabel
	mov rsi,[rbx+8]
	call print_string

	; write end of xlabel text
	mov rsi,.svg_text+61
	mov rdx,8
	call print_chars

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; WRITE Y-LABEL ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.y_label:

	; check if we wanted to write an ylabel
	test r12,4
	jz .grid
		
	; write ylabel text start
	mov rsi,.svg_text
	mov rdx,34
	call print_chars

	; write ylabel font color
	movzx rsi, dword [rbx+84]
	mov rdx,6
	call print_int_h_n_digits

	; write more of ylabel text
	mov rsi,.svg_text+34
	mov rdx,13
	call print_chars

	; write ylabel font size
	movzx rsi, byte [rbx+96]
	call print_int_d

	; write more of ylabel text
	mov rsi,.svg_text+47
	mov rdx,7
	call print_chars

	; write ylabel x location
	movzx rsi, byte [rbx+96]
	add si, word [rbx+34]
	push rsi		; save x to stack
	call print_int_d

	; write more of ylabel text
	mov rsi,.svg_text+54
	mov rdx,5
	call print_chars

	; write ylabel y location
	mov rsi,[.plot_height]
	shr rsi,1
	add rsi,[.plot_y_start]
	push rsi		; save y to stack
	call print_int_d

	; write more of ylabel text
	mov rsi,.svg_text+59
	mov rdx,1
	call print_chars

	; rotate ylabel text
	mov rsi,.svg_rotate
	mov rdx,19
	call print_chars

	; write -90 degrees
	mov rsi,-90
	call print_int_d

	; more rotate text
	mov rsi,.svg_rotate+19
	mov rdx,1
	call print_chars

	; x center for rotate
	pop rsi
	mov r9,rsi
	pop rsi
	push r9
	call print_int_d

	; more rotate text
	mov rsi,.svg_rotate+20
	mov rdx,1
	call print_chars

	; y center for rotate
	pop rsi
	call print_int_d

	; end of rotate text
	mov rsi,.svg_rotate+21
	mov rdx,2
	call print_chars

	; write more of ylabel text
	mov rsi,.svg_text+60
	mov rdx,1
	call print_chars

	; write actual ylabel
	mov rsi,[rbx+16]
	call print_string

	; write end of ylabel text
	mov rsi,.svg_text+61
	mov rdx,8
	call print_chars

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; WRITE  GRID ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.grid:

	; check if we wanted to write the grid
	test r12,8
	jz .tick_labels

	; start with major gridlines
	
	; <g stroke-linecap="square" stroke="#
	mov rsi,.svg_g_start
	mov rdx,36
	call print_chars

	; print axis stroke color
	movzx rsi,dword [rbx+80]
	mov rdx,6
	call print_int_h_n_digits

	; " stroke-width="
	mov rsi,.svg_g_start+36
	mov rdx,16
	call print_chars

	; print grid stroke width 
	movzx rsi, byte [rbx+100]
	call print_int_d

	; px">\n
	mov rsi,.svg_g_start+52
	mov rdx,5
	call print_chars

	; draw the horizontal major lines now
	movzx r13, byte [rbx+89]	; number of y ticks in r13
	
	; track y value in working1
	cvtsi2sd xmm0,[.plot_y_start]
	movsd [.working1],xmm0
	
	; y_tick_distance in working2
	mov r15,r13
	dec r15
	mov [.working2],r15
	cvtsi2sd xmm0,[.working2]
	cvtsi2sd xmm1,[.plot_height]
	divsd xmm1,xmm0
	movsd [.working2],xmm1

.loop_y_grid:

	; <line x1="
	mov rsi,.svg_line
	mov rdx,10
	call print_chars

	; x_left
	mov rsi,[.plot_x_start]
	call print_int_d

	; " x2="
	mov rsi,.svg_line+10
	mov rdx,6
	call print_chars

	; x_right
	mov rsi,[.plot_x_start]
	add rsi,[.plot_width]
	call print_int_d

	; " y1="
	mov rsi,.svg_line+16
	mov rdx,6
	call print_chars

	; y_left
	movsd xmm0,[.working1]
	mov rsi,8
	call print_float

	; " y2="
	mov rsi,.svg_line+22
	mov rdx,6
	call print_chars

	; y_right
	movsd xmm0,[.working1]
	mov rsi,8
	call print_float

	; "/>\n
	mov rsi,.svg_line+28
	mov rdx,4
	call print_chars

	; go to next line
	movsd xmm0,[.working1]
	movsd xmm1,[.working2]
	addsd xmm0,xmm1
	movsd [.working1],xmm0

	dec r13	; loop
	jnz .loop_y_grid

	; draw the vertical major lines now
	movzx r13, byte [rbx+88]	; number of x ticks in r13
	
	; track x value in working1
	cvtsi2sd xmm0,[.plot_x_start]
	movsd [.working1],xmm0
	
	; x_tick_distance in working2
	mov r15,r13
	dec r15
	mov [.working2],r15
	cvtsi2sd xmm0,[.working2]
	cvtsi2sd xmm1,[.plot_width]
	divsd xmm1,xmm0
	movsd [.working2],xmm1

.loop_x_grid:

	; <line x1="
	mov rsi,.svg_line
	mov rdx,10
	call print_chars

	; x_top
	movsd xmm0,[.working1]
	mov rsi,8
	call print_float

	; " x2="
	mov rsi,.svg_line+10
	mov rdx,6
	call print_chars

	; x_bottom
	movsd xmm0,[.working1]
	mov rsi,8
	call print_float

	; " y1="
	mov rsi,.svg_line+16
	mov rdx,6
	call print_chars

	; y_top
	mov rsi,[.plot_y_start]
	call print_int_d

	; " y2="
	mov rsi,.svg_line+22
	mov rdx,6
	call print_chars

	; y_bottom
	mov rsi,[.plot_y_start]
	add rsi,[.plot_height]
	call print_int_d

	; "/>\n
	mov rsi,.svg_line+28
	mov rdx,4
	call print_chars

	; go to next line
	movsd xmm0,[.working1]
	movsd xmm1,[.working2]
	addsd xmm0,xmm1
	movsd [.working1],xmm0

	dec r13	; loop
	jnz .loop_x_grid

	; </g>\n
	mov rsi,.svg_g_end
	mov rdx,5
	call print_chars

	; now the minor gridlines

	; check if we even have enough subdivisions
	movzx r14, byte [rbx+91]	; number of subdivisions per y tick in r14
	movzx r15, byte [rbx+90]	; number of subdivisions per x tick in r15

	; if both r14 or r15 <=1, skip this section entirely
	cmp r14,2
	jge .y_minor_gridlines
	cmp r15,2
	jge .y_minor_gridlines
	jmp .tick_labels

.y_minor_gridlines:

	; <g stroke-linecap="square" stroke="#
	mov rsi,.svg_g_start
	mov rdx,36
	call print_chars

	; print axis stroke color
	movzx rsi, dword [rbx+80]
	mov rdx,6
	call print_int_h_n_digits

	; " stroke-width="
	mov rsi,.svg_g_start+36
	mov rdx,16
	call print_chars

	; print grid stroke width 
	movzx rsi, byte [rbx+101]
	call print_int_d

	; px">\n
	mov rsi,.svg_g_start+52
	mov rdx,5
	call print_chars

	; horizontal gridlines first
	movzx r13, byte [rbx+91]	; number of y ticks in r13
	movzx r14, byte [rbx+93]	; number of subdivisions per y tick in r14
	
	cmp r14,2
	jl .x_minor_gridlines

	; track y value in working1
	cvtsi2sd xmm0,[.plot_y_start]
	movsd [.working1],xmm0
	
	; y minor tick distance in working2
	mov r15,r13
	dec r15
	imul r15,r14
	mov [.working2],r15
	cvtsi2sd xmm0,[.working2]
	cvtsi2sd xmm1,[.plot_height]
	divsd xmm1,xmm0
	movsd [.working2],xmm1

	dec r13
	dec r14

.loop_y_grid_minor:

	mov r15,r14

	; go to first minor line after major line
	movsd xmm0,[.working1]
	movsd xmm1,[.working2]
	addsd xmm0,xmm1
	movsd [.working1],xmm0

.loop_y_grid_minor_inner:

	; <line x1="
	mov rsi,.svg_line
	mov rdx,10
	call print_chars

	; x_left
	mov rsi,[.plot_x_start]
	call print_int_d

	; " x2="
	mov rsi,.svg_line+10
	mov rdx,6
	call print_chars

	; x_right
	mov rsi,[.plot_x_start]
	add rsi,[.plot_width]
	call print_int_d

	; " y1="
	mov rsi,.svg_line+16
	mov rdx,6
	call print_chars

	; y_left
	movsd xmm0,[.working1]
	mov rsi,8
	call print_float

	; " y2="
	mov rsi,.svg_line+22
	mov rdx,6
	call print_chars

	; y_right
	movsd xmm0,[.working1]
	mov rsi,8
	call print_float

	; "/>\n
	mov rsi,.svg_line+28
	mov rdx,4
	call print_chars

	; go to next minor line
	movsd xmm0,[.working1]
	movsd xmm1,[.working2]
	addsd xmm0,xmm1
	movsd [.working1],xmm0

	dec r15	; loop inner
	jnz .loop_y_grid_minor_inner

	dec r13 ; loop outer
	jnz .loop_y_grid_minor

.x_minor_gridlines:

	movzx r13, byte [rbx+90]	; number of x ticks in r13
	movzx r14, byte [rbx+92]	; number of subdivisions per x tick in r14
	
	cmp r14,2
	jl .end_minor_gridlines

	; track x value in working1
	cvtsi2sd xmm0,[.plot_x_start]
	movsd [.working1],xmm0
	
	; x minor tick distance in working2
	mov r15,r13
	dec r15
	imul r15,r14
	mov [.working2],r15
	cvtsi2sd xmm0,[.working2]
	cvtsi2sd xmm1,[.plot_width]
	divsd xmm1,xmm0
	movsd [.working2],xmm1

	dec r13
	dec r14

.loop_x_grid_minor:

	mov r15,r14

	; go to first minor line after major line
	movsd xmm0,[.working1]
	movsd xmm1,[.working2]
	addsd xmm0,xmm1
	movsd [.working1],xmm0

.loop_x_grid_minor_inner:

	; <line x1="
	mov rsi,.svg_line
	mov rdx,10
	call print_chars

	; x_left
	movsd xmm0,[.working1]
	mov rsi,8
	call print_float

	; " x2="
	mov rsi,.svg_line+10
	mov rdx,6
	call print_chars

	; x_right
	movsd xmm0,[.working1]
	mov rsi,8
	call print_float

	; " y1="
	mov rsi,.svg_line+16
	mov rdx,6
	call print_chars

	; y_left
	mov rsi,[.plot_y_start]
	call print_int_d

	; " y2="
	mov rsi,.svg_line+22
	mov rdx,6
	call print_chars

	; y_right
	mov rsi,[.plot_y_start]
	add rsi,[.plot_height]
	call print_int_d

	; "/>\n
	mov rsi,.svg_line+28
	mov rdx,4
	call print_chars

	; go to next minor line
	movsd xmm0,[.working1]
	movsd xmm1,[.working2]
	addsd xmm0,xmm1
	movsd [.working1],xmm0

	dec r15	; loop inner
	jnz .loop_x_grid_minor_inner

	dec r13 ; loop outer
	jnz .loop_x_grid_minor

.end_minor_gridlines:

	; </g>\n
	mov rsi,.svg_g_end
	mov rdx,5
	call print_chars

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; WRITE TICK LABELS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.tick_labels:
	; check if we wanted to write the tick labels
	test r12,16
	jz .plot_data

	; start with y tick labels
	
	; <g text-anchor="end" fill="#
	mov rsi,.svg_g_y_ticks
	mov rdx,28
	call print_chars

	; print tick label stroke color
	movzx rsi,dword [rbx+84]
	mov rdx,6
	call print_int_h_n_digits

	; " font-size="
	mov rsi,.svg_g_y_ticks+28
	mov rdx,13
	call print_chars

	; print tick label font size 
	movzx rsi, byte [rbx+97]
	call print_int_d

	; px">\n
	mov rsi,.svg_g_y_ticks+41
	mov rdx,5
	call print_chars

	; write the y tick labels now
	movzx r13, byte [rbx+89]	; number of y ticks in r13
	
	; track y value in working1
	cvtsi2sd xmm0,[.plot_y_start]
	movzx rsi, byte [rbx+97]			; tick label font size
	shr rsi,1
	cvtsi2sd xmm1,rsi
	addsd xmm0,xmm1
	movsd [.working1],xmm0
	
	; y_tick_distance in working2
	mov r15,r13
	dec r15
	mov [.working2],r15
	cvtsi2sd xmm0,[.working2]
	cvtsi2sd xmm1,[.plot_height]
	divsd xmm1,xmm0
	movsd [.working2],xmm1

	; y value tick delta in working3
	movsd xmm0,[rbx+62]	; ymax
	movsd [.working3],xmm0

	; track y axis value in working4
	movsd xmm0,[rbx+62]	; ymax
	movsd xmm1,[rbx+54]	; ymin
	mov [.working4],r15		; number of divisions
	cvtsi2sd xmm2,[.working4] ; number of divisions
	subsd xmm0,xmm1
	divsd xmm0,xmm2
	movsd [.working4],xmm0

.loop_y_tick_labels:

	; <text x="
	mov rsi,.svg_tick_text
	mov rdx,9
	call print_chars

	; x_coord
	mov rsi,[.plot_x_start]
	movzx r8, byte [rbx+98]
	sub rsi,r8
	call print_int_d

	; " y="
	mov rsi,.svg_tick_text+9
	mov rdx,5
	call print_chars

	; y_coord
	movsd xmm0,[.working1]
	mov rsi,8
	call print_float

	; ">
	mov rsi,.svg_tick_text+14
	mov rdx,2
	call print_chars

	; actual tick value
	movsd xmm0,[.working3]
	movzx rsi, byte [rbx+93]
	call print_float

	; </text>\n
	mov rsi,.svg_tick_text+16
	mov rdx,8
	call print_chars

	; go to next label location
	movsd xmm0,[.working1]
	movsd xmm1,[.working2]
	addsd xmm0,xmm1
	movsd [.working1],xmm0

	; go to next tick value
	movsd xmm0,[.working3]
	movsd xmm1,[.working4]
	subsd xmm0,xmm1
	movsd [.working3],xmm0

	dec r13	; loop
	jnz .loop_y_tick_labels	

	; </g>\n
	mov rsi,.svg_g_end
	mov rdx,5
	call print_chars

	; onto x tick labels

	; <g text-anchor="start" fill="#
	mov rsi,.svg_g_x_ticks
	mov rdx,30
	call print_chars

	; print tick label stroke color
	movzx rsi,dword [rbx+84]
	mov rdx,6
	call print_int_h_n_digits

	; " font-size="
	mov rsi,.svg_g_x_ticks+30
	mov rdx,13
	call print_chars

	; print tick label font size 
	movzx rsi, byte [rbx+97]
	call print_int_d

	; px">\n
	mov rsi,.svg_g_x_ticks+43
	mov rdx,5
	call print_chars

	movzx r13, byte [rbx+88]	; number of x ticks in r13
	
	; track x value in working1
	cvtsi2sd xmm0,[.plot_x_start]
	movzx rsi, byte [rbx+97]			; tick label font size
	shr rsi,1
	cvtsi2sd xmm1,rsi
	subsd xmm0,xmm1
	movsd [.working1],xmm0
	
	movsd [.working1],xmm0
	
	; x_tick_distance in working2
	mov r15,r13
	dec r15
	mov [.working2],r15
	cvtsi2sd xmm0,[.working2]
	cvtsi2sd xmm1,[.plot_width]
	divsd xmm1,xmm0
	movsd [.working2],xmm1

	; x value tick delta in working3
	movsd xmm0,[rbx+38]	; xmin
	movsd [.working3],xmm0

	; track x axis value in working4
	movsd xmm0,[rbx+46]	; xmax
	movsd xmm1,[rbx+38]	; xmin
	mov [.working4],r15		; number of divisions
	cvtsi2sd xmm2,[.working4] ; number of divisions
	subsd xmm0,xmm1
	divsd xmm0,xmm2
	movsd [.working4],xmm0

.loop_x_tick_labels:

	; <text x="
	mov rsi,.svg_tick_text
	mov rdx,9
	call print_chars

	; x_coord
	movsd xmm0,[.working1]
	mov rsi,8
	call print_float	

	; " y="
	mov rsi,.svg_tick_text+9
	mov rdx,5
	call print_chars

	; y_coord
	mov rsi,[.plot_y_start]
	add rsi,[.plot_height]
	movzx r8, byte [rbx+99]
	add rsi,r8
	call print_int_d

	; "
	mov rsi,.svg_tick_text+14
	mov rdx,1
	call print_chars

	; rotate the text 90deg clockwise
	;  transform="rotate(
	mov rsi,.svg_rotate
	mov rdx,19
	call print_chars

	; 90 deg
	mov rsi,90
	call print_int_d

	; ,
	mov rsi,.svg_rotate+19
	mov rdx,1
	call print_chars

	; x_coord
	movsd xmm0,[.working1]
	mov rsi,8
	call print_float	
	
	; ,
	mov rsi,.svg_rotate+20
	mov rdx,1
	call print_chars
	
	; y_coord
	mov rsi,[.plot_y_start]
	add rsi,[.plot_height]
	movzx r8, byte [rbx+99]
	add rsi,r8
	call print_int_d

	; )"
	mov rsi,.svg_rotate+21
	mov rdx,2
	call print_chars

	; >
	mov rsi,.svg_tick_text+15
	mov rdx,1
	call print_chars

	; actual tick value
	movsd xmm0,[.working3]
	movzx rsi, byte [rbx+92]
	call print_float

	; </text>\n
	mov rsi,.svg_tick_text+16
	mov rdx,8
	call print_chars

	; go to next label location
	movsd xmm0,[.working1]
	movsd xmm1,[.working2]
	addsd xmm0,xmm1
	movsd [.working1],xmm0

	; go to next tick value
	movsd xmm0,[.working3]
	movsd xmm1,[.working4]
	addsd xmm0,xmm1
	movsd [.working3],xmm0

	dec r13	; loop
	jnz .loop_x_tick_labels

	; </g>\n
	mov rsi,.svg_g_end
	mov rdx,5
	call print_chars

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; PLOT DATA ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.plot_data:

	

	; one final flush of the print buffer
	call print_buffer_flush
	
	; pops


	; return
	ret

; memory space to save intermediate math

.working1:
	dq 0

.working2:
	dq 0

.working3:
	dq 0

.working4:
	dq 0

.scaling_x:
	dq 0

.scaling_y:
	dq 0

.plot_width:
	dq 0

.plot_height:
	dq 0

.plot_x_start:
	dq 0

.plot_y_start:
	dq 0

; svg-related grammar

.svg_header:
	db `<svg viewBox="0 0  " xmlns="http://www.w3.org/2000/svg" width="" height="" style="background-color:#">\n`

.svg_text:
	db `<text text-anchor="middle" fill="#" font-size="px" x="" y=""></text>\n`

.svg_g_y_ticks:
	db `<g text-anchor="end" fill="#" font-size="px">\n`

.svg_g_x_ticks:
	db `<g text-anchor="start" fill="#" font-size="px">\n`

.svg_tick_text:
	db `<text x="" y=""></text>\n`

.svg_rotate:
	db ` transform="rotate(,,)"`

.svg_line:
	db `<line x1="" x2="" y1="" y2=""/>\n`

.svg_path:
	db `<path stroke="#" stroke-width="px" fill="none" d="M L"/>\n`

.svg_g_start:
	db `<g stroke-linecap="square" stroke="#" stroke-width="px">\n`

.svg_dasharray:
	db `stroke-dasharray="," `

.svg_g_end:
	db `</g>\n`

.svg_g_marker:
	db `<g fill="#">\n`

.svg_circle:
	db `<circle cx="" cy="" r=""/>\n`

.svg_rect:
	db `<rect x="" y="" width="" height="" fill="#" stroke="#" stroke-width="px"/>\n`

.svg_opacity:
	db `fill-opacity="%"`

.svg_bezier_grammar:
	db ` QCA`

.svg_footer:
	db `</svg>\n`

%endif
