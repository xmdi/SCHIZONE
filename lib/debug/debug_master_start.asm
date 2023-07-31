%ifndef DEBUG_MASTER_START
%define DEBUG_MASTER_START

; dependency
%include "lib/io/print_chars.asm"

debug_master_start:
; void debug_master_start(void);
;	Begins tracking quantities for debugging purposes.
;	Records GP (and stack pointer) and XMM register state & timestamp.

;	save GP registers
	mov [.GP_regs+0],rax
	mov [.GP_regs+8],rbx
	mov [.GP_regs+16],rcx
	mov [.GP_regs+24],rdx
	mov [.GP_regs+32],rdi
	mov [.GP_regs+40],rsi
	mov [.GP_regs+48],rsp
	mov [.GP_regs+56],rbp
	mov [.GP_regs+64],r8
	mov [.GP_regs+72],r9
	mov [.GP_regs+80],r10
	mov [.GP_regs+88],r11
	mov [.GP_regs+96],r12
	mov [.GP_regs+104],r13
	mov [.GP_regs+112],r14
	mov [.GP_regs+120],r15

; save XMM registers
	movdqu [.XMM_regs+0],xmm0	
	movdqu [.XMM_regs+16],xmm1	
	movdqu [.XMM_regs+32],xmm2	
	movdqu [.XMM_regs+48],xmm3	
	movdqu [.XMM_regs+64],xmm4	
	movdqu [.XMM_regs+80],xmm5	
	movdqu [.XMM_regs+96],xmm6	
	movdqu [.XMM_regs+112],xmm7	
	movdqu [.XMM_regs+128],xmm8	
	movdqu [.XMM_regs+144],xmm9	
	movdqu [.XMM_regs+160],xmm10	
	movdqu [.XMM_regs+176],xmm11	
	movdqu [.XMM_regs+192],xmm12	
	movdqu [.XMM_regs+208],xmm13	
	movdqu [.XMM_regs+224],xmm14	
	movdqu [.XMM_regs+240],xmm15	





	ret		; return

.GP_regs:
	times 16 dq 0	; 16 quadwords for the normal registers

.XMM_regs:
	times 32 dq 0	; 32 quadwords for the XMM registers

.timestamp:
	dq 0		; seconds
	dq 0		; microseconds
%endif
