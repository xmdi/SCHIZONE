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
	
	

	mov rbx,rsi
	
	; start at beginning of PRINT_BUFFER
	mov [PRINT_BUFFER_LENGTH],0	

	


	ret

%endif
