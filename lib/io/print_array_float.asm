%ifndef PRINT_ARRAY_FLOAT
%define PRINT_ARRAY_FLOAT

; dependency
%include "lib/io/print_chars.asm"
%include "lib/io/print_float.asm"
%include "lib/io/print_float_scientific.asm"

print_array_float:
; void print_array_float(int {rdi}, int* {rsi}, int {rdx}, int {rcx}, int {r8}
;	void* {r9}, int {r10});
; Prints float array starting at {rsi} to file descriptor {rdi}. Number of rows
;	and columns in {rdx} and {rcx} respectively. Low 32 bits of {r8}
;	contain extra column offset, and high 32 bits contain the extra row 
;	offset. {r9} points to the function used to print floats in the
;	desired format. {r10} indicates the number of significant figures.

	push rsi
	push rdx
	push rax
	push rbx
	push rbp
	push r8
	push r9
	push r10
	push r11
	push r12	
	push r13	
	push r14

	; grab col offsets in {rbp} 
	; keep row offsets in {r8}
	mov rbp,r8
	shl rbp,32
	shr rbp,32
	shr r8,32

	; adjust {rbp} to include byte-width of signed long
	add rbp,8

	; {r14} contains the number of sig figs
	mov r14,r10

	; {r10} will always point to the current row
	mov r10,rsi
	; {r11} will contain number of rows remaining
	mov r11,rdx	
	; {r12} will save number of cols
	mov r12,rcx

	; e.g: {r8} should contain the distance between A(0,n) and A(1,n)
	mov rax,rcx	; {rax} = Ncols
	mul rbp		; {rax} = Ncols*width_col
	add r8,rax	; {r8} contains the distance specified above

	; print `[`;
	mov rsi,.grammar
	mov rdx,1
	call print_chars

.loop_rows:
	mov rbx,r10	; {rbx} will be adjusted to index into the array	
	mov r13,r12	; {r13} will contain number of cols remaining

.loop_cols:

	; print number
	movsd xmm0,[rbx]	
	mov rsi,r14
	call r9

	call print_buffer_flush

	cmp r13,1	; skip comma on the last one
	je .no_comma

	; print `,`
	mov rsi,.grammar+1
	mov rdx,1
	call print_chars
		
.no_comma:

	add rbx,rbp	; go onto next column
	dec r13		; loop until out of columns
	jnz .loop_cols
	
	add r10,r8	; go onto the next row

	cmp r11,1
	jle .done

	; print `;\n`
	mov rsi,.grammar+3
	mov rdx,2
	call print_chars

	dec r11
	jnz .loop_rows

.done:

	; print `];\n`;
	mov rsi,.grammar+2
	mov rdx,3
	call print_chars

	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rbp
	pop rbx
	pop rax
	pop rdx	
	pop rsi	

	ret		; return

.grammar:
	db `[,];\n`

%endif
