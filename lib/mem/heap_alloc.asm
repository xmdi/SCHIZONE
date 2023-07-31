%ifndef HEAP_ALLOC
%define HEAP_ALLOC

heap_alloc:
; void* {rax} heap_alloc(long {rdi});
;	Allocates a chunk of {rdi} bytes on the heap (plus an 8-byte header
;	and an 8-byte footer), and returns the address to the start of this
;	memory in {rax}. Returns {rax}=0 if suitable space not available on the 
;	heap.
	
	push rdi
	push rsi
	push r8

	mov rax,HEAP_START_ADDRESS	; init {rax} to header of first chunk
	add rdi,7
	and rdi,-8			; round up to multiple of 8-bytes

.next_block:	; check this chunk of memory
	mov rsi,[rax]	; move header into {rsi}
	test rst,1	; if the LSB is 1, the chunk has already been allocated
	jnz .cant_use_this_chunk
			
.chunk_not_allocated:
	sub rsi,rdi	; {rsi}-={rdi} to indicate excess space in the chunk
	jl .cant_use_this_chunk	; if the chunk was too small, it can't be used	

	cmp rsi,16	
	jg .chunk_big_enough	; if the chunk has more than 16 bytes extra
				; space, it will need to be broken up

	add rdi,rsi		; otherwise just increase the size of
				; the allocation to eat up the extra bytes
	xor rsi,rsi		; set {rsi} to indicate a perfectly-filled chunk	
	
.chunk_big_enough:	; we found a suitable chunk
	mov r8,rdi	; create new chunk header/footer in {r8}
	inc r8		; set LSB to indicate "allocated" in header/footer
	mov [rax],r8	; set header at [{rax}]
	add rdi,rax	; set {rdi} to footer location
	add rdi,8
	mov [rdi],r8	; set footer at [{rdi}]
	add rax,8	; adjust {rax} to point to memory, not to header
	test rsi,rsi	; if we perfectly filled the chunk
	jz .perfectly_filled_chunk	; then return {rax}

.breakup_chunk:		; break the remainder of the original chunk into a new 
			; empty chunk
	
	sub rsi,16	; save 16 bytes for header and footer
	add rdi,8	; set {rdi} to header location
	mov [rdi],rsi	; move header (unallocated LSB) into [{rsi}]
	add rdi,rsi	; set {rdi} to footer location
	add rdi,8

	cmp rdi,(HEAP_START_ADDRESS+HEAP_SIZE)	; check if we're @ the heap end
	jl .not_last_block
	add rdi,2
.not_last_block:
	mov [rdi],rsi	; move footer into [{rdi}]
	jmp .done		

.cant_use_this_chunk:

	and rsi,-8	; round {rsi} down to 8-byte multiple to get the chunk
			; length
	add rax,rsi	; set {rax} to the footer address
	add rax,8
	mov rsi,[rax]	; grab the footer
	add rax,8	; set {rax} to header of next chunk
	test rsi,2	; check for the "final chunk" bit set
	jz .next_block	; otherwise go to the next chunk

	xor rax,rax
.done:
	pop r8
	pop rsi
	pop rdi
	ret
	
.perfectly_filled_chunk:
	add r8,1
	mov [rdi],r8
	jmp .done

%endif
%endif
