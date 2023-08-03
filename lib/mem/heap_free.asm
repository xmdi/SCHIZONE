%ifndef HEAP_FREE
%define HEAP_FREE

heap_free:
; bool {rax} heap_free(void* {rdi});
;	Frees the chunk of memory starting at address {rdi}. Returns {rax}=0 on success,
;	{rax}=1 on fail.

	push r8

	mov r8,[rdi-8]			; set {r8} to selected chunk header
	test r8,1			; checks if this chunk was even allocated
	jnz .valid_pointer
	mov rax,1

	pop r8
	ret				; if chunk not allocated, just leave
	
.valid_pointer:
	
	push rdi
	push rsi
	push r9

	cmp r8,(HEAP_START_ADDRESS)	; If we are the first chunk,
	je .header_address_found	; the current chunk header is the beginning
					; of the new freed chunk.
	mov rsi,[rdi-16]		; previous chunk footer in {rsi}		
	test rsi,1			; If previous chunk is allocated,
	jnz .header_address_found	; the current chunk header is the beginning
					; of the new freed chunk.
	sub r8,rsi			; adjust {r8} to point to the previous chunk
	sub r8,16			; header

.header_address_found:
	mov rsi,[rdi-8]			; {rsi} becomes initial chunk header
	add rsi,rdi			; 
	add rsi,7			; {rsi} points to next chunk header
	mov r9,rsi
	sub r9,r8			; {r9} points to initial chunk footer
	cmp r9,(HEAP_START_ADDRESS+HEAP_SIZE-8)	; If we are the last chunk,
	jge .footer_address_found	; the current chunk footer is the end of the
					; new freed chunk.
	mov rdi,[rsi]			; next chunk header in {rdi}
	test rdi,1			; If next chunk is allocated,
	jnz .footer_address_found	; the current chunk footer is the end of the
					; new freed chunk.
	add r9,rdi			; adjust {r9} to point to the next chunk footer
	add r9,16

.footer_address_found:
	mov rsi,r9
	sub rsi,r9
	sub rsi,8			; {rsi} contains length of the new free chunk

	mov [r8],rsi			; set header to unallocated chunk header
					; of the appropriate size
	cmp r9,(HEAP_START_ADDRESS+HEAP_SIZE-8)	; If we weren't the last chunk,
	jne .not_last_block		; don't change the footer.
	add rsi,2			; adjust footer value to indicate final header
.not_last_block:
	mov [r9],rsi			; set footer to unallocated chunk footer
					; of the appropriate size.
	xor rax,rax

	pop r9
	pop rsi
	pop rdi
	pop r8
	ret				; leave

%endif
