%ifndef WRITE_BITMAP
%define WRITE_BITMAP

write_bitmap:
; void write_bitmap(int {rdi}, void* {rsi}, int {edx}, int {ecx});
;	Writes the {edx}x{ecx} (WxH) bitmap with ARGB data at {rsi} to 
;	the file descriptor in {rdi}.

	push rax
	push rbx
	push rbp
	mov rbp,rsp
	push rsi
	push rdx
	SYS_PUSH_SYSCALL_CLOBBERED_REGISTERS

	mov [.header+18],edx	; insert bitmap width into header data
	mov [.header+22],ecx	; insert bitmap height into header data
	imul edx,ecx
	shl edx,2
	mov ebx,edx		; save pixel array size in {ebx}
	mov [.header+34],edx	; insert pixel array size into header data
	add edx,122	
	mov [.header+2],edx	; insert bitmap filesize into header data

	; write the BMP header to the file descriptor
	mov rax,SYS_WRITE
	mov rsi,.header
	mov rdx,122
	syscall
	
	; write the BMP pixel array to the file descriptor
	mov rax,SYS_WRITE
	mov rsi,[rbp-8]
	mov edx,ebx
	syscall
	
	SYS_POP_SYSCALL_CLOBBERED_REGISTERS
	pop rdx
	pop rsi
	pop rbp
	pop rbx
	pop rax

	ret		; return

.header:
	db 0x42,0x4D	; "BM"
	dd 0		; reserved for size of bitmap file
	dw 0		; unused
	dw 0		; unused
	dd 122		; offset to pixel data
	dd 108		; remaining bytes in DIB header
	dd 0		; reserved for bitmap width
	dd 0		; reserved for bitmap height
	dw 1		; number of color planes
	dw 32		; bits per pixel
	dd 3		; BI_BITFIELDS, no compression
	dd 0		; reserved for size of bitmap data
	dd 2835		; 72 DPI horizontal resolution
	dd 2835		; 72 DPI vertical resolution
	dd 0		; number of colors (unused)
	dd 0 		; number of important colors (unused)
	db 0x00,0x00,0xFF,0x00	; red bitmask
	db 0x00,0xFF,0x00,0x00	; green bitmask
	db 0xFF,0x00,0x00,0x00	; blue bitmask
	db 0x00,0x00,0x00,0xFF	; alpha bitmask
	db 0x20,0x6E,0x69,0x57	; "Win " colorspace
	times 48 db 0		; unused for "Win " colorspace

%endif
