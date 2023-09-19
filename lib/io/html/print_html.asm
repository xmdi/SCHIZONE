%ifndef PRINT_HTML
%define PRINT_HTML

; dependency	
%include "lib/io/print_chars.asm"
%include "lib/io/print_string.asm"
%include "lib/io/print_int_d.asm"
%include "lib/io/svg/scatter_plot.asm"

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
	;	10 = unordered list
	;	11 = ordered list
	; 	12 = table
	;	13 = image
	;	14 = video
	;	15 = scatter_plot

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
	db ; type of item (10-11)
	dw ; number of elements
	dq ; address of null-terminated string of text to print
	; repeat above dq for all elements in the list

.table_structure:	; sample table structure
	dq ; address of next item in linked list
	db 12 ; type of item (12)
	dw ; number of rows
	dw ; number of columns
	dq ; address of null-terminated string of text to print in each cell
	; repeat above dq for all columns in all rows

.embed_structure:	; sample embed structure
	dq ; address of next item in linked list
	db ; type of item (13-14)
	dq ; address of null-terminated string of file path
	dw ; pixel width
	dw ; pixel height

.scatter_structure:	; sample structure for scatter plot
	dq ; address of next item in linked list
	db 15 ; type of item (15)
	dq ; address of scatter-plot plot_structure 
		; (see /lib/io/svg/scatter_plot.asm)

%endif

	; pushes



	mov rbx,rsi	; keep linked list entry in {rbx}

	; print html front matter
	mov rsi,.head
	mov rdx,30
	call print_chars

.loop:

	cmp byte [rbx+8],0
	jl .go_next
	cmp byte [rbx+8],0
	je .write_p
	cmp byte [rbx+8],7
	jl .write_h
	je .write_raw
	cmp byte [rbx+8],8
	je .write_hr
	cmp byte [rbx+8],9
	je .write_break
	cmp byte [rbx+8],10
	je .write_unordered_list
	cmp byte [rbx+8],11
	je .write_ordered_list
	cmp byte [rbx+8],12
	je .write_table
	cmp byte [rbx+8],13
	je .write_image
	cmp byte [rbx+8],14
	je .write_video
	cmp byte [rbx+8],15
	je .write_scatter

.go_next:
	mov rdx,[rbx]
	test rdx,rdx
	jz .done
	
	mov rbx,[rbx]
	jmp .loop

.done:

	; print html back matter
	mov rsi,.foot
	mov rdx,16
	call print_chars



	; pops

	ret			;return


.write_p:
	mov rsi,.p_start
	mov rdx,3
	call print_chars

	mov rsi,[rbx+9]
	call print_string

	mov rsi,.p_end
	mov rdx,5
	call print_chars

	jmp .go_next

.write_h:
	mov rsi,.h_start
	mov rdx,2
	call print_chars

	movzx rsi, byte [rbx+8]
	call print_int_d

	nov rsi,.h_start+2
	mov rdx,1
	call print_chars

	mov rsi,[rbx+9]
	call print_string

	mov rsi,.h_end
	mov rdx,3
	call print_chars

	movzx rsi, byte [rbx+8]
	call print_int_d

	nov rsi,.h_end+3
	mov rdx,2
	call print_chars

	jmp .go_next

.write_raw:
	mov rsi,[rbx+9]
	call print_string

	jmp .go_next

.write_hr:
	mov rsi,.hr
	mov rdx,5
	call print_chars

	jmp .go_next

.write_break:
	mov rsi,.page_break
	mov rdx,32
	call print_chars

	jmp .go_next

.write_unordered_list:
	mov rsi,.unordered_list_start
	mov rdx,4
	call print_chars

	movzx rcx, word [rbx+9]

	cmp rcx,0
	jle .loop_unordered_list_end
	mov r8,rbx
	add r8,11

.loop_unordered_list:
		
	mov rsi,.list_element_start
	mov rdx,4
	call print_chars

	mov rsi,[r8]
	call print_string	

	mov rsi,.list_element_end
	mov rdx,6
	call print_chars

	add r8,8
	dec rcx
	jnz .loop_unordered_list

.loop_unordered_list_end:

	mov rsi,.unordered_list_end
	mov rdx,6
	call print_chars

	jmp .go_next

.write_ordered_list:
	mov rsi,.ordered_list_start
	mov rdx,4
	call print_chars

	movzx rcx, word [rbx+9]

	cmp rcx,0
	jle .loop_ordered_list_end
	mov r8,rbx
	add r8,11

.loop_ordered_list:
		
	mov rsi,.list_element_start
	mov rdx,4
	call print_chars

	mov rsi,[r8]
	call print_string	

	mov rsi,.list_element_end
	mov rdx,6
	call print_chars

	add r8,8
	dec rcx
	jnz .loop_ordered_list

.loop_ordered_list_end:

	mov rsi,.ordered_list_end
	mov rdx,6
	call print_chars

	jmp .go_next

.write_image:
	mov rsi,.image
	mov rdx,10
	call print_chars

	mov rsi,[rbx+9]
	call print_string

	mov rsi,.image+10
	mov rdx,9
	call print_chars

	movzx rsi, word [rbx+17]
	call print_int_d

	mov rsi,.image+19
	mov rdx,10
	call print_chars

	movzx rsi, word [rbx+19]
	call print_int_d

	mov rsi,.image+29
	mov rdx,4
	call print_chars

	jmp .go_next

	db `<video src="" width="" height="" controls/>\n`
.write_video:
	mov rsi,.video
	mov rdx,12
	call print_chars

	mov rsi,[rbx+9]
	call print_string

	mov rsi,.video+12
	mov rdx,9
	call print_chars

	movzx rsi, word [rbx+17]
	call print_int_d

	mov rsi,.video+21
	mov rdx,10
	call print_chars

	movzx rsi, word [rbx+19]
	call print_int_d

	mov rsi,.video+31
	mov rdx,13
	call print_chars

	jmp .go_next







.head:
	db `<!doctype html>\n<html>\n<body>\n`

.h_start:
	db `<h>`

.h_end:
	db `</h>\n`

.p_start:
	db `<p>`

.p_end:
	db `</p>\n`

.hr:
	db `<hr>\n`

.page_break:
	db `<div style="break-after:page"/>\n`

.unordered_list_start:
	db `<ul>`

.unordered_list_end:
	db `</ul>\n`

.ordered_list_start:
	db `<ul>`

.ordered_list_end:
	db `</ul>\n`

.list_element_start:
	db `<li>`

.list_element_end:
	db `</li>\n`

.table_start:
	db `<table>`

.table_end:
	db `</table>\n`

.table_row_start:
	db `<tr>`

.table_row_end:
	db </tr>\n`

.table_data_start:
	db `<td>`

.table_data_end:
	db </td>\n`

.image:
	db `<img src="" width="" height=""/>\n`

.video:
	db `<video src="" width="" height="" controls/>\n`

.foot:
	db `</body>\n</html>`

%endif
