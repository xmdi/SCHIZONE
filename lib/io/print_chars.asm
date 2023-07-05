%ifndef PRINT_CHARS
%define PRINT_CHARS

; dependency	
%include "lib/io/print_buffer_flush.asm"
; also requires PRINT_BUFFER and its PRINT_BUFFER_SIZE to be defined

print_chars:
; void print_chars(int {rdi}, char* {rsi}, uint {rdx});
; 	Writes {rdx} chars of char array starting at {rsi} to file 
;	descriptor {rdi}.

	push rsi		; save registers
	push rdx
	push rcx
	push rax
	push r8

	mov rax,PRINT_BUFFER
	add rax,[PRINT_BUFFER_LENGTH] 	; {rax} points to the next free byte 
					; 	in buffer
	add rdx,rsi			; {rdx} points past the last address 
					;	of string
	mov r8,PRINT_BUFFER			
	add r8,PRINT_BUFFER_SIZE	; {r8} points past the last address 
					;	of buffer
.buffer_load_loop:
	mov byte cl,[rsi]	; *** can revise this to do more than 1 byte at a time
	mov byte [rax],cl	; move byte into next free buffer slot
	inc rsi			; move to next byte of string 
	inc rax			; move to next byte of buffer
	cmp r8,rax		; unless we've filled the buffer
	ja .no_flush 		; do the next character	
	mov rcx,PRINT_BUFFER_SIZE; quickly set the buffer to "full"
	mov [PRINT_BUFFER_LENGTH],rcx
	call print_buffer_flush	; flush the buffer
	mov rax,PRINT_BUFFER	; reset {rax} to the start of the buffer
.no_flush:
	cmp rsi,rdx		; continue until we hit the end of our string
	jb .buffer_load_loop
	sub rax,PRINT_BUFFER	; compute number of bytes in buffer
	mov [PRINT_BUFFER_LENGTH],rax ; save number of bytes in buffer
	
	pop r8		; restore registers
	pop rax
	pop rcx
	pop rdx
	pop rsi

	ret			;return

%endif
