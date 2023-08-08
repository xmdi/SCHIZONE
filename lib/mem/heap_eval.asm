%ifndef HEAP_EVAL
%define HEAP_EVAL

heap_eval:
; ulong {rax}, ulong {rdx} heap_eval(void);
; 	Returns number of allocated bytes on heap in {rax} and number of
;	allocated chunks in {rdx}.

	push rdi
	push rsi

	xor rax,rax			; zero counter for allocated bytes
	xor rdx,rdx			; zero counter for allocated chunks

	mov rdi,HEAP_START_ADDRESS	; start at beginning of heap	

.loop:
	mov rsi,[rdi]
	test rsi,1
	jz .unallocated
	dec rsi
	add rax,rsi
	inc rdx
.unallocated:
	add rdi,rsi
	add rdi,16
	cmp rdi,(HEAP_START_ADDRESS+HEAP_SIZE)
	jl .loop
	
	pop rsi
	pop rdi

	ret				; leave

%endif
