%ifndef SET_FOREGROUND
%define SET_FOREGROUND

set_foreground:
; void set_foreground(void* {rdi}, void* {rsi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});
;	Copies pixels from the {r8d}x{r9d} bitmap at {rsi} to
;	the {edx}x{ecx} bitmap at {rdi} starting at the pixel
;	at corner ({r10d},{r11d}). Only copies pixels with nonzero
;	transparency byte.

	push rsi
	push rax
	push rbx
	push r9
	push r12
	push r13
	push r15
	
	; adjust number of rows down if we slide off the bottom
	mov eax,r11d
	add eax,r9d
	cmp eax,ecx
	jle .good_y
	sub eax,ecx
	sub r9d,eax
.good_y:
	; compute valid number of columns (we won't plot beyond this)
	mov eax,r10d
	add eax,r8d
	cmp eax,edx
	jle .good_x
	sub eax,edx
	mov r15d,r8d
	sub r15d,eax
.good_x:

	shl edx,2 ; {edx} contains byte width of background bitmap
	mov eax,edx
	imul eax,r11d
	shl r10d,2
	add eax,r10d
	add rax,rdi	; {rax} points to starting corner of bg bmp
	shr r10d,2

	; skip if we have zero rows left
	test r9d,r9d
	jz .ret

	; loop thru rows of foreground bitmap
.row_loop:
	mov rbx,rax	; {rbx} will track the target pixel in the loops
	xor r12d,r12d	; track col pixel count in {r12}

	; loop thru cols of foreground bitmap	
.col_loop:
	cmp r12d,r15d
	jg .skip
	mov r13d,[rsi]
	test r13d,0xFF000000
	jz .skip	
	mov [rbx],r13d
.skip:
	add rsi,4
	add rbx,4
	inc r12d
	cmp r12d,r8d
	jl .col_loop

	add rax,rdx
	dec r9d
	jnz .row_loop	

.ret:
	shr edx,2
	pop r15
	pop r13
	pop r12
	pop r9
	pop rbx
	pop rax
	pop rsi
	ret

%endif
