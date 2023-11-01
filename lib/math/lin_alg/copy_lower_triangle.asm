%ifndef COPY_LOWER_TRIANGLE
%define COPY_LOWER_TRIANGLE

copy_lower_triangle:
; void copy_lower_triangle(double* {rdi}, double* {rsi}, uint {rdx});
; 	Copies lower triangle of {rdx}x{rdx} matrix at address {rsi} to matrix 
; 	at address {rdi}. Overwrites the diagonals of the destination matrix.

	push rdi
	push rsi
	push rax
	push rdx
	push rcx
	push r8
	push r9
	push r10
	push r11

	mov r8,8	; {r8} tracks running column byte-offset (r8+=8 each iter)

	mov rcx,rdx
	shl rcx,3	; {rcx} contains byte-width of matrix row

	; {rsi} tracks current row start address in source matrix
	; {rdi} tracks current row start address in destination matrix
	; {r11} tracks running column byte offset in the column loop

.loop_rows:
	mov r9,rsi
	mov r10,rdi
	xor r11,r11	

.loop_cols:
	mov rax, qword [r9]
	mov [r10],rax
	add r9,8
	add r10,8
	add r11,8

	cmp r11,r8
	jb .loop_cols	; continue to end of the row
	
	add rsi,rcx		; proceed to next row in source matrix
	add rdi,rcx		; proceed to next row in destination matrix
	add r8,8		; shift 1 column to right in starting byte-offset

	cmp r8,rcx
	jbe .loop_rows	; continue to end of matrices

	pop r11
	pop r10
	pop r9
	pop r8
	pop rcx
	pop rdx
	pop rax
	pop rsi
	pop rdi

	ret

%endif
