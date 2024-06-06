%ifndef DEBUG
%define DEBUG

; dependency
%include "lib/io/print_chars.asm"
%include "lib/io/print_int_b.asm"
%include "lib/io/print_int_o.asm"
%include "lib/io/print_int_d.asm"
%include "lib/io/print_int_h.asm"
%include "lib/io/print_float.asm"
%include "lib/io/print_registers.asm"
%include "lib/io/print_stack.asm"
%include "lib/io/print_string.asm"
%include "lib/sys/exit.asm"

; "debug_exit 8" exits from program and returns 8
%macro debug_exit 1
	mov dil,%1
	call exit
%endmacro
	
; "debug_reg_b r8" prints binary integer contents of {r8} followed by \n
%macro debug_reg_b 1
	push rdi
	push rsi
	push rdx

	mov rdi,SYS_STDOUT
	mov rsi,%1
	call print_int_b
	mov rsi,debug.grammar
	mov rdx,1
	call print_chars
	call print_buffer_flush

	pop rdx
	pop rsi
	pop rdi
%endmacro	
		
; "debug_reg_o r8" prints octal integer contents of {r8} followed by \n
%macro debug_reg_o 1
	push rdi
	push rsi
	push rdx

	mov rdi,SYS_STDOUT
	mov rsi,%1
	call print_int_o
	mov rsi,debug.grammar
	mov rdx,1
	call print_chars
	call print_buffer_flush

	pop rdx
	pop rsi
	pop rdi
%endmacro	
	
; "debug_reg r8" prints decimal integer contents of {r8} followed by \n
%macro debug_reg 1
	push rdi
	push rsi
	push rdx

	mov rdi,SYS_STDOUT
	mov rsi,%1
	call print_int_d
	mov rsi,debug.grammar
	mov rdx,1
	call print_chars
	call print_buffer_flush

	pop rdx
	pop rsi
	pop rdi
%endmacro	
	
; "debug_reg_h r8" prints hexadecimal integer contents of {r8} followed by \n
%macro debug_reg_h 1
	push rdi
	push rsi
	push rdx

	mov rdi,SYS_STDOUT
	mov rsi,%1
	call print_int_h
	mov rsi,debug.grammar
	mov rdx,1
	call print_chars
	call print_buffer_flush

	pop rdx
	pop rsi
	pop rdi
%endmacro	
		
; "debug_reg_f xmm8" prints float contents of {xmm8} followed by \n
%macro debug_reg_f 1
	push rdi
	push rsi
	push rdx
	sub rsp,16
	movdqu [rsp+0],xmm0

	mov rdi,SYS_STDOUT
	mov rsi,8
	movsd xmm0,%1
	call print_float
	mov rsi,debug.grammar
	mov rdx,1
	call print_chars
	call print_buffer_flush

	movdqu xmm0,[rsp+0]
	add rsp,16
	pop rdx
	pop rsi
	pop rdi
%endmacro	
		
; "debug_line" prints a horizontal line followed by \n
%macro debug_line 0
	push rdi
	push rsi
	push rdx

	mov rdi,SYS_STDOUT
	mov rsi,debug.line
	mov rdx,81
	call print_chars
	call print_buffer_flush

	pop rdx
	pop rsi
	pop rdi
%endmacro	
		
; "debug_regs print_int_d" prints decimal register contents followed by \n
%macro debug_regs 1
	push rdi
	push rsi
	push rdx
	
	push %1
	push SYS_STDOUT
	call print_registers

	mov rdi,SYS_STDOUT
	mov rsi,debug.grammar
	mov rdx,1
	call print_chars
	call print_buffer_flush

	pop rdx
	pop rsi
	pop rdi
%endmacro	
			
; "debug_stack 8 print_int_h" prints top 8 qwords on stack as hex ints 
;	followed by \n
%macro debug_stack 2
	push rdi
	push rsi
	push rdx

	mov rdi,SYS_STDOUT
	mov rsi,%1
	mov rdx,%2
	call print_stack

	mov rsi,debug.grammar
	mov rdx,1
	call print_chars
	call print_buffer_flush

	pop rdx
	pop rsi
	pop rdi
%endmacro	

; "debug_literal `test`" prints `test` (up to 8 bytes) followed by \n  
;	followed by \n
%macro debug_literal 1
	push rdi
	push rsi
	push rdx

	mov rsi,%1
	mov [debug.buffer],rsi

	mov rdi,SYS_STDOUT
	mov rsi,debug.buffer
	call print_string

	mov rsi,debug.grammar
	mov rdx,1
	call print_chars
	call print_buffer_flush

	xor rsi,rsi
	mov [debug.buffer],rsi

	pop rdx
	pop rsi
	pop rdi
%endmacro	

; pushes all regs
%macro debug_push_all 0

	push rdi
	push rsi
	push rdx
	push rcx
	push rbx
	push rax
	push rbp
	push r8
	push r9
	push r10
	push r11
	push r12
	push r13
	push r14
	push r15

	sub rsp,256
	movdqu [rsp+0],xmm0
	movdqu [rsp+16],xmm1
	movdqu [rsp+32],xmm2
	movdqu [rsp+48],xmm3
	movdqu [rsp+64],xmm4
	movdqu [rsp+80],xmm5
	movdqu [rsp+96],xmm6
	movdqu [rsp+112],xmm7
	movdqu [rsp+128],xmm8
	movdqu [rsp+144],xmm9
	movdqu [rsp+160],xmm10
	movdqu [rsp+176],xmm11
	movdqu [rsp+192],xmm12
	movdqu [rsp+208],xmm13
	movdqu [rsp+224],xmm14
	movdqu [rsp+240],xmm15

%endmacro	

; pops all regs
%macro debug_pop_all 0

	movdqu xmm0,[rsp+0]
	movdqu xmm1,[rsp+16]
	movdqu xmm2,[rsp+32]
	movdqu xmm3,[rsp+48]
	movdqu xmm4,[rsp+64]
	movdqu xmm5,[rsp+80]
	movdqu xmm6,[rsp+96]
	movdqu xmm7,[rsp+112]
	movdqu xmm8,[rsp+128]
	movdqu xmm9,[rsp+144]
	movdqu xmm10,[rsp+160]
	movdqu xmm11,[rsp+176]
	movdqu xmm12,[rsp+192]
	movdqu xmm13,[rsp+208]
	movdqu xmm14,[rsp+224]
	movdqu xmm15,[rsp+240]
	add rsp,256

	pop r15
	pop r14
	pop r13
	pop r12
	pop r11
	pop r10
	pop r9
	pop r8
	pop rbp
	pop rax
	pop rbx
	pop rcx
	pop rdx
	pop rsi
	pop rdi

%endmacro	

debug.buffer:
	dq 0
	db 0
debug.line:
	times 80 db `=`	
debug.grammar:	
	db `\n`

	
%endif
