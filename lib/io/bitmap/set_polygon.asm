%ifndef SET_POLYGON
%define SET_POLYGOM

; dependency
%include "lib/io/bitmap/set_line.asm"

set_polygon:
; void set_polygon(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 double* {r8}, int {r9});
;	Draws polygon with {r9} vertices in 2*{r9} length long (8-byte) int array at {r8}
;	to ARGB data array starting at {rdi} for an 
;	{edx}x{ecx} (WxH) image with a fill color in the low 32 bits of {rsi}.

	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push rax

	cmp r9,1
	jle .ret

	mov r12,r8
	mov r13,r9

	; last shall be first
	mov rax,r13
	shl rax,4
	add rax,r13
	mov r8,[r12]
	mov r9,[r12+8]
	mov r10,[rax]
	mov r11,[rax+8]
	call set_line

	dec r13

	; loop thru all rows
.loop:
	mov r8,[r12+0]
	mov r9,[r12+8]
	mov r10,[r12+16]
	mov r11,[r12+24]
	call set_line
	add r12,16
	dec r13
	jnz .loop

.ret:
	pop rax
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	ret

%endif
