%ifndef SCATTER_PLOT
%define SCATTER_PLOT

; dependencies
%include "lib/io/print_chars.asm"

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
	movzx rsi, dword [rbx+32] ; width
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
	movzx rsi, dword [rbx+34] ; height
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

	; write svg header
	mov rsi,.svg_header
	mov rdx,18
	call print_chars

	

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
