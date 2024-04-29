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

	mov r15,[framebuffer_hud_init.hud_head]
	cmp r15,0
	je .quit	

.iterate_top_level_hud_elements:

	mov r14,[r15+12]
	push r14	; push current hud element to [rsp+16] (for recursion)
	
	movzx rax, word [r15+0]
	push rax	
	movzx rax, word [r15+2]
	push rax
	; parent X location always at [rsp+8]
	; parent Y location always at [rsp+0]

	
.iterate_hud_element:
	
	cmp byte [r14+0],0b10000001 ; rectangle
	je .process_rectangle

	cmp byte [r14+0],0b10000010 ; text
	je .process_text

	jmp .invalid_element_definition

.process_rectangle:

	mov esi,[r14+9]
	mov rax,0x100000000
	or rsi,rax
	; may need to invert stacking dir TODO
	movzx r8d, word [r14+1]
	movzx r9d, word [r14+3]
	movzx r10d, word [r14+5]
	movzx r11d, word [r14+7]
	mov rax,[rsp+8]	
	add r8d,eax
	add r10d,eax
	mov rax,[rsp+0]	
	add r9d,eax
	add r11d,eax
	call set_filled_rect

	; if children, recurse on them, TODO
	cmp qword [r14+30], qword 0
	je .no_kids

	push r14
	movzx rax, word [r14+1]
	push rax	
	movzx rax, word [r14+3]
	push rax
	
	mov r14,[r14+30]

	call .iterate_hud_element
	add rsp,24
	mov r14,[rsp+16]
	

.no_kids:
	; goto cousin
	mov r14,[r14+22]
	cmp r14,0
	je .no_cousins	
	jmp .iterate_hud_element


.process_text:

	mov esi,[r14+14]
	mov rax,0x100000000
	or rsi,rax
	; may need to invert stacking dir TODO
	movzx r8d, word [r14+1]
	movzx r9d, word [r14+3]
	mov rax,[rsp+8]	
	add r8d,eax
	mov rax,[rsp+0]	
	add r9d,eax
	movzx r10d, byte [r14+5]
	mov r11,[r14+30]
	mov r12,[r14+6]
	call set_text

	; goto cousin
	mov r14,[r14+22]
	cmp r14,0
	je .no_cousins	
	jmp .iterate_hud_element


.invalid_element_definition:

.no_cousins:

	add rsp,24
		
	mov r15,[r15+4]
	cmp r15,0
	je .quit	
	jmp .iterate_top_level_hud_elements

.quit:

	ret

%endif
