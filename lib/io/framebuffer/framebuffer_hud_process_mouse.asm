%ifndef FRAMEBUFFER_HUD_PROCESS_MOUSE
%define FRAMEBUFFER_HUD_PROCESS_MOUSE

%include "lib/io/framebuffer/framebuffer_hud_init.asm"
; void* {rax} framebuffer_hud_init(void);

%include "lib/io/framebuffer/framebuffer_mouse_init.asm"

%include "lib/io/framebuffer/framebuffer_init.asm"

framebuffer_hud_process_mouse:
; void framebuffer_hud_process_mouse(void);
; Processes mouse to interact with HUD initialized by framebuffer_hud_init. 

	mov r11b,byte [framebuffer_mouse_init.mouse_state] ; {r11b} has mouse state

	movsxd r12,[framebuffer_mouse_init.mouse_x] ; {r12} has mouse x
	movsxd r13,[framebuffer_mouse_init.mouse_y] ; {r13} has mouse y

	mov r14,[framebuffer_hud_init.hud_head] ; {r14} has first HUD element
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

	mov al,[r14+0]
	and al,0b01111111	

	cmp al,0b00000000 ; top level "group" element
	je .process_group
	
	cmp al,0b00000001 ; rectangle
	je .process_rectangle

	cmp al,0b00000010 ; text
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

	mov al,[r14+0]
	test al,0b10000000
	jz .invisible_rectangle

	; check if our mouse collides with the visible element,
	
	movzx rax, word [r14+17]
	movzx rbx, word [r14+19]
	movzx rcx, word [r14+21]
	movzx rdx, word [r14+23]

	mov rbp,[rsp+16]	
	add rax,rbp
	add rcx,rbp
	mov rbp,[rsp+8]	
	add rbx,rbp
	add rdx,rbp
	mov r9,rdx
	mov r10,rax

	cmp r12,rax
	jl .not_within_rectangle
	cmp r12,rcx
	jg .not_within_rectangle
	cmp r13,rbx
	jl .not_within_rectangle
	cmp r13,rdx
	jg .not_within_rectangle

	; within rectangle

	call [r14+38]

	jmp .ret

.not_within_rectangle:


.invisible_rectangle:


	; if children, recurse on them
	cmp qword [r14+9], qword 0
	je .no_rectangle_kids

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

	mov al,[r14+0]
	test al,0b10000000
	jz .invisible_text
	

.invisible_text:

	; goto cousin
	mov r14,[r14+1]
	cmp r14,0
	jne .parse_cousins	

.invalid_element_definition:
.no_cousins:
.ret:
	ret

%endif
