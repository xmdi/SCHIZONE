%ifndef FRAMEBUFFER_INIT
%define FRAMEBUFFER_INIT

%include "lib/mem/heap_alloc.asm"
%include "lib/io/file_open.asm"

framebuffer_init:
; void framebuffer_init(void);
; Initializes a framebuffer for drawing purposes. User will need to be part of
; video group and call this routine from a tty that isn't running X11/etc.
; Needs a heap to be instantiated of the appropriate size (~16 MB to be safe).
; No error handling; deal with it.
	
	push rdi
	push rsi
	push rdx
	push rax

	mov rdi,.filename
	mov rsi,SYS_READ_WRITE
	mov rdx,SYS_DEFAULT_PERMISSIONS
	call file_open
	mov [.framebuffer_file_descriptor],al	; save file descriptor	

	mov rdi,1280
	call heap_alloc
	mov [.screen_info_address],rax	; save screen info address for later access
	
	; get framebuffer info
	mov dil,.framebuffer_file_descriptor
	mov rsi,SYS_FBIOGET_VSCREENINFO
	mov rdx,rax
	mov rax,SYS_IOCTL
	syscall

	mov esi,[.screen_info_address+0]
	imul esi,[.screen_info_address+4]
	imul esi,[.screen_info_address+24]
	shr esi,3		; number of bytes in buffer
	mov [.framebuffer_size],rsi

	mov rdi,rsi
	call heap_alloc
	mov [.framebuffer_address],rax	; save framebuffer address

	pop rax
	pop rdx
	pop rsi
	pop rdi

	ret

.filename:
	db `/dev/fb0\0` 

.framebuffer_file_descriptor:
	db 0

.framebuffer_size:
	dq 0

.screen_info_address:
	dq 0

.framebuffer_address:
	dq 0

%endif
