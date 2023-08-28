%ifndef PARSE_DELIMITED_FLOAT_FILE
%define PARSE_DELIMITED_FLOAT_FILE

; dependencies
%include "lib/io/parse_float.asm"
%include "lib/mem/find_byte_offset.asm"
%include "lib/io/read_chars.asm"
%include "lib/mem/memcopy.asm"

parse_delimited_float_file:
; void parse_delimited_float_file(double* {rdi}, uint {rsi}, uint {rdx},
;		 uint {rcx}, void* {r8}, char {r9b});
;	Reads {rdx} double-precision floating point values from the file
;	descriptor in {rsi} and places them in the array starting at
;	address {rdi}. Uses a buffer of length {rcx} starting at address
;	{r8} for this purpose. The delimiter between floats is passed in
;	{r9b}.

	push rax
	push rbx
	push rcx
	push rdx
	push rdi
	push rsi
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push r14

	xor rbx,rbx	; initialize break flag to zero	
	mov r10,rdi	; save array_start in {r10}
	mov r11,rdx	; array_length in {r11}

	; attempt to load bytes from file into buffer
	mov rdi,rsi	; file_descriptor in {rdi}
	mov rsi,r8	; buffer_start in {rsi}
	mov rdx,rcx	; buffer_length in {rdx}

.read_loop:

	call read_chars

	cmp rax,rdx	; if we read the number of bytes we intended, start loop
	je .good_read
	cmp rax,0	; if end of file or error, break
	jle .done
	inc rbx		; if other amount of bytes, break after this iteration

.good_read:

	mov r12,rdx	; {r12} contains number of bytes left in buffer
	mov r13,rsi	; {r13} contains cursor address to parse the buffer
			; 	( it moves from {rsi} to ({rsi}+{rdx}-1) )
	; parse starting at beginning of the buffer
.parse_loop:

	; for the remaining bytes in the buffer, calculate the offset 
	;	to the next delimited character {r9b}
	push rdi
	push rsi
	push rdx
	mov rdi,r13
	mov sil,r9b
	mov rdx,r12
	call find_byte_offset	; offset to next delimiter in {rax}
	pop rdx
	pop rsi
	pop rdi

	; if -1 and no break flag, shift the last piece of buffer into 
	;	the beginning and fill the buffer with additional bytes
	; 	from {rsi} (jmp to .read_loop).
	; if -1 and break flag, parse the last float
	; if >0, call parse_float and copy to the destination array,
	;	and then parse the next float (jmp to .parse_loop)
	
	cmp rax,0
	jge .not_buffer_end

	test rbx,rbx
	jg .parse_last_float

	push rdi
	push rsi
	push rdx
	mov rdi,rsi
	mov rsi,r13
	mov rdx,r12
	call memcopy	; shift the last part of buffer to the start
	pop rdx
	pop rsi
	pop rdi

	push rsi
	push rdx
	add rsi,r12
	sub rdx,r12
	mov r14,rdx
	call read_chars
	pop rdx
	pop rsi

	cmp rax,r14	; if we read the number of bytes we intended, start loop
	je .good_read
	cmp rax,0	; if end of file or error, break
	jle .done
	inc rbx		; if other amount of bytes, break after this iteration

	jmp .good_read

.parse_last_float:

	mov rdi,[READ_BUFFER+1]
	call exit

	push rdi
	mov rdi,r13
	call parse_float	; parsed float in {xmm0}
	pop rdi
	movq [r10],xmm0		; drop float into array

.done:
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rsi
	pop rdi
	pop rdx
	pop rcx
	pop rbx
	pop rax

	ret

.not_buffer_end:

	push rdi
	mov rdi,r13
	call parse_float	; parsed float in {xmm0}
	pop rdi

	sub r12,rax		; subtract bytes left in buffer
	dec r12	
	add r13,rax
	inc r13			; adjust cursor to next float start
	movq [r10],xmm0		; drop float into array
	add r10,8
	dec r11
	jz .done		; break out when out of floats to parse	

	mov rax,rdx
	add rax,rsi		; {rax} points passed the buffer
	cmp r13,rax
	jge .read_loop		; if we exactly exhausted the buffer
				; parse the next buffer-full

	jmp .parse_loop		; otherwise continue to the next one

%endif
