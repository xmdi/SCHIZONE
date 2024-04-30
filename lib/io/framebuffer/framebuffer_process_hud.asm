%ifndef FRAMEBUFFER_PROCESS_HUD
%define FRAMEBUFFER_PROCESS_HUD

%include "lib/io/framebuffer/framebuffer_hud_init.asm"
; void* {rax} framebuffer_hud_init(void);

%include "lib/io/framebuffer/framebuffer_init.asm"

%include "lib/io/bitmap/set_rect.asm"

%include "lib/io/bitmap/set_filled_rect.asm"

%include "lib/io/bitmap/set_text.asm"

framebuffer_process_hud:
; void framebuffer_process_hud(void);
; Processes HUD initialized by framebuffer_hud_init. 

	; clear the buffer first
	mov rdi,[framebuffer_hud_init.hudbuffer_address]
	xor sil,sil
	mov rdx,[framebuffer_init.framebuffer_size]
	call memset

	mov rdi,[framebuffer_hud_init.hudbuffer_address]
	mov edx,[framebuffer_init.framebuffer_width]
	mov ecx,[framebuffer_init.framebuffer_height]

	mov r14,[framebuffer_hud_init.hud_head]
	cmp r14,0
	je .quit

	push r14
	movzx rax, word [r14+17]
	push rax	
	movzx rax, word [r14+19]
	push rax
	call .parse_cousins

	add rsp,24

.quit:

	ret

.parse_cousins: ; this address gets "called" every time we find a child
	; expects parent X and Y position (not relative to his parents, but absolute)
	; and parent address on the stack
	
	cmp byte [r14+0],0b10000000 ; top level "group" element
	je .process_group
	
	cmp byte [r14+0],0b10000001 ; rectangle
	je .process_rectangle

	cmp byte [r14+0],0b10000010 ; text
	je .process_text

	jmp .invalid_element_definition

.process_group:
	
	; if children, recurse on them
	cmp qword [r14+9], qword 0
	je .no_group_kids

	push r14
	movzx rax, word [r14+17]
	push rax	
	movzx rax, word [r14+19]
	push rax
	
	mov r14,[r14+9]

	call .parse_cousins

	mov r14,[rsp+16]
	add rsp,24

.no_group_kids:
	; goto cousin
	mov r14,[r14+1]
	cmp r14,0
	je .no_cousins	
	jmp .parse_cousins

.process_rectangle:

	mov esi,[r14+25]
	mov rax,0x100000000
	or rsi,rax
	; may need to invert stacking dir
	movzx r8d, word [r14+17]
	movzx r9d, word [r14+19]
	movzx r10d, word [r14+21]
	movzx r11d, word [r14+23]
	mov rax,[rsp+16]	
	add r8d,eax
	add r10d,eax
	mov rax,[rsp+8]	
	add r9d,eax
	add r11d,eax
	call set_filled_rect

	; if children, recurse on them
	cmp qword [r14+9], qword 0
	je .no_rectangle_kids
	mov r13,r14


	push r14
	movzx rax, word [r14+17]
	add rax,[rsp+24]
	push rax	
	movzx rax, word [r14+19]
	add rax,[rsp+24]
	push rax
	
	mov r14,[r14+9]

	call .parse_cousins

	mov r14,[rsp+16]
	add rsp,24

.no_rectangle_kids:
	; goto cousin
	mov r14,[r14+1]
	cmp r14,0
	je .no_cousins	
	jmp .parse_cousins

.process_text:

	mov esi,[r14+30]
	mov rax,0x100000000
	or rsi,rax
	movzx r8d, word [r14+17]
	movzx r9d, word [r14+19]
	mov rax,[rsp+16]	
	add r8d,eax
	mov rax,[rsp+8]	
	add r9d,eax
	movzx r10d, byte [r14+21]
	mov r11,[r14+38]
	mov r12,[r14+22]
	call set_text

	; goto cousin
	mov r14,[r14+1]
	cmp r14,0
	jne .parse_cousins	

.invalid_element_definition:
.no_cousins:
	ret

%endif
