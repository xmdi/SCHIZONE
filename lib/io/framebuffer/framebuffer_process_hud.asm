%ifndef FRAMEBUFFER_PROCESS_HUD
%define FRAMEBUFFER_PROCESS_HUD

%include "lib/io/framebuffer/framebuffer_hud_init.asm"
; void* {rax} framebuffer_hud_init(void);

%include "lib/io/framebuffer/framebuffer_init.asm"

%include "lib/io/bitmap/set_rect.asm"
; void set_rect(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});
;	Draws rectangle from ({r8d},{r9d}) to ({r10d},{r11d}) (from (0,0)
;	@ top-left) in ARGB data array starting at {rdi} for an 
;	{edx}x{ecx} (WxH) image with a border color in the low 32 bits of
;	{rsi}

%include "lib/io/bitmap/set_filled_rect.asm"
; void set_filled_rect(void* {rdi}, int {rsi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, int {r11d});

%include "lib/io/bitmap/set_text.asm"
; void set_text(void* {rdi}, int {esi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, char* {r11}, void* {r12});
;	Renders null-terminated character array starting at {r11} beginning 
;	at pixel ({r8d},{r9d}) (from (0,0) @ top-left) in ARGB data array 
;	starting at {rdi} for an {edx}x{ecx} (WxH) image in the color value
;	in {esi}. Font defined at {r12} and font scaling in {r10}.

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

	movzx rax, word [r15+0]
	push rax	
	movzx rax, word [r15+2]
	push rax
	; parent X location always at [rsp+8]
	; parent Y location always at [rsp+0]

	mov r14,[r15+12]
	
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

	; goto cousin
	mov r14,[r14+22]
	cmp r14,0
	je .no_cousins	
	jmp .iterate_hud_element


.process_text:

	%include "lib/io/bitmap/set_text.asm"
; void set_text(void* {rdi}, int {esi}, int {edx}, int {ecx},
;		 int {r8d}, int {r9d}, int {r10d}, char* {r11}, void* {r12});
;	Renders null-terminated character array starting at {r11} beginning 
;	at pixel ({r8d},{r9d}) (from (0,0) @ top-left) in ARGB data array 
;	starting at {rdi} for an {edx}x{ecx} (WxH) image in the color value
;	in {esi}. Font defined at {r12} and font scaling in {r10}.

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

	add rsp,16
		
	mov r15,[r15+4]
	cmp r15,0
	je .quit	
	jmp .iterate_top_level_hud_elements

.quit:

	ret

%endif
