%ifndef PRINT_HTML
%define PRINT_HTML

; dependency	
%include "lib/io/print_chars.asm"

print_html:
; void print_html(int {rdi}, struct* {rsi});
; 	Writes HTML file to file descriptor {rdi} for the linked list of items
;	starting at address {rsi}.

%if 0
.item_structure:
	dq ; address of next item in linked list
	db ; type of item
	;	0 = p
	;	1 = h1
	;	2 = h2
	;	3 = h3
	;	4 = h4
	;	5 = h5
	;	6 = h6
	;	7 = raw text
	;	8 = hr (horizontal line)
	;	9 = page break
	;	10 = list
	; 	11 = table
	;	12 = image
	;	13 = video
	;	14 = scatter_plot

; the rest of the structure will vary depending on the byte above

.text_structure:	; sample text structures
	dq ; address of next item in linked list
	db ; type of item (0-7)
	dq ; address of null-terminated string of text to print

.format_structure:	; sample format structures
	dq ; address of next item in linked list
	db ; type of item (8-9)

.list_structure:	; sample list structure
	dq ; address of next item in linked list
	db 10 ; type of item (10)
	dw ; number of elements
	dq ; address of null-terminated string of text to print
	; repeat above dq for all elements in the list

.table_structure:	; sample table structure
	dq ; address of next item in linked list
	db 11 ; type of item (11)
	dw ; number of rows
	dw ; number of columns
	dq ; address of null-terminated string of text to print in each cell
	; repeat above dq for all columns in all rows

.embed_structure:	; sample embed structure
	dq ; address of next item in linked list
	db ; type of item (12-13)
	dq ; address of null-terminated string of file path

.scatter_structure:	; sample structure for scatter plot
	dq ; address of next item in linked list
	db 14 ; type of item (14)
	dq ; address of scatter-plot plot_structure 
		; (see /lib/io/svg/scatter_plot.asm)


%endif



	ret			;return

%endif
