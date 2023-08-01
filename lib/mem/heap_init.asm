%ifndef HEAP_INIT
%define HEAP_INIT

heap_init:
; void heap_init(void);
;	Initializes a heap of HEAP_SIZE at HEAP_START_ADDRESS (values set for
;	the preprocessor). HEAP_SIZE should be a multiple of 16.

	push rdi

	; set header long
	mov rdi,(HEAP_SIZE-16)	; take 8 bytes for each the header and footer
	mov [HEAP_START_ADDRESS],rdi	; set header long

	; set footer long
	add rdi,2		; 2nd bit set to 1 to indicate footer
	mov [HEAP_START_ADDRESS+HEAP_SIZE-8],rdi	; set footer long

	pop rdi
	ret

%endif
