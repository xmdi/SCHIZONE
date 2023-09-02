%ifndef SCATTER_PLOT
%define SCATTER_PLOT

; dependencies
%include "lib/io/print_chars.asm"

; input data structures
%if 0
plot_structure:
	dq ; address of null-terminated title string
	dq ; address of null-terminated x-label string
	dq ; address of null-terminated y-label string
	dq ; address of linked list for datasets
	dq ; plot width (px)
	dq ; plot height (px)
	dq ; plot margins (px)
	dq ; x-min (double)
	dq ; x-max (double)
	dq ; y-min (double)
	dq ; y-max (double)
	dq ; legend left x-coordinate (px)
	dq ; legend top y-coordinate (px)
	dq ; legend width (px)
	dd ; #XXXXXX RGB background color
	dd ; #XXXXXX RGB axis color
	dd ; #XXXXXX RGB font color
	db ; number of major x-ticks
	db ; number of major y-ticks
	db ; minor subdivisions per x-tick
	db ; minor subdivisions per y-tick
	db ; significant digits on x values
	db ; significant digits on y values
	db ; title font size (px)
	db ; vertical margin below title (px)
	db ; axis label font size (px)
	db ; tick & legend label font size (px)
	db ; horizontal margin right of y-tick labels (px)
	db ; vertical margin above x-tick labels (px)
	db ; grid major stroke thickness (px)
	db ; grid minor stroke thickness (px)
	db ; width for y-axis ticks (px)
	db ; height for x-axis ticks (px)
	db ; flags:
		; bit 0 (LSB)	= show title?
		; bit 1		= show x-label?
		; bit 2		= show y-label?
		; bit 3		= draw grid?
		; bit 4		= show tick labels?
		; bit 5		= draw legend?

dataset_structure:
	dq ; address of next dataset in linked list
	dq ; address of null-terminated label string
	dq ; address of first x-coordinate
	dq ; extra stride between x-coord elements
	dq ; address of first y-coordinate
	dq ; extra stride between y-coord elements
	dq ; number of elements
	dd ; #XXXXXX RGB marker color
	dd ; #XXXXXX RGB line color
	dd ; #XXXXXX RGB fill color
	db ; marker size (px)
	db ; line thickness (px)
	db ; fill opacity (%)
	db ; flags:
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
	



	ret

%endif
