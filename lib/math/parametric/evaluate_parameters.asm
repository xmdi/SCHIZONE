%ifndef EVALUATE_PARAMETERS
%define EVALUATE_PARAMETERS

evaluate_parameters:
; bool {rax} evaluate_parameters(void* {rdi}, void* {rsi}, void* {rdx});
; 	Evaluates function at address {rdx} (which takes and places its own 
; 	float parameters on the stack, (with its own input {rdi} indicating 
; 	number of float parameters passed).
; 	{rdi} points to a linked list of output parameters.
; 	{rsi} points to a linked list of input parameters. 
; 	{rax} returns 1 on failure, 0 on success.

; TODO: input flag to indicate how you want different parameters combined 
; ("grid-like"?, "together"?)

%if 0
; linked list structure for input and output parameters
; note: parameters are 8-byte double precision floats

parameter_list:
	dq ; address of next parameter in list (0 on last element)
	dq ; address of first parameter value
	dq ; extra stride between parameter values
	dq ; number of values (only matters for first input parameter in linked list)
	dq ; work zone (track address of current element), initial value unused
%endif

; snag some registers
	push rdi
	push rsi
	push rdx
	push rcx
	push r12
	push r13
	push r14
	push r15

; save function inputs
	mov r12,rdi
	mov r13,rsi
	mov r14,rdx

; populate "current element" of first input and output param
	mov r8,[rsi+8] ; set work zone to starting element
	mov [rsi+32],r8
	mov r8,[rdi+8] ; set work zone to starting element
	mov [rdi+32],r8

; compute the number of input parameters
	mov rcx,1
	mov rsi,[rsi]
	test rsi,rsi
	jz .done_counting_inputs

.count_inputs:
	mov r8,[rsi+8] ; set work zone to starting element
	mov [rsi+32],r8
	inc rcx
	mov rsi,[rsi]
	test rsi,rsi
	jnz .count_inputs
.done_counting_inputs: ; number of inputs in rcx

; compute the number of output parameters
	mov rdx,1
	mov rdi,[rdi]
	test rdi,rdi
	jz .done_counting_outputs
.count_outputs:
	mov r8,[rdi+8] ; set work zone to starting element	
	mov [rdi+32],r8
	inc rdx
	mov rdi,[rdi]
	test rdi,rdi
	jnz .count_outputs
.done_counting_outputs: ; number of outputs in rdx

; put maximum of number of inputs and outputs in r15
	cmp rcx,rdx
	cmovl rcx,rdx
	mov r15,rcx

; allocate sufficient stack space for that many values
	shl r15,3	; multiply r15 by 8 to count bytes
	sub rsp,r15

.function_call_loop:
	xor rcx,rcx
	mov rsi,r13

; push all input parameters onto the stack
.loop_set_inputs:
	mov r8,[rsi+32] ; "push" value at current element address of current parameter
	mov r8,[r8]

	mov [rsp+rcx],r8
	mov r8,[rsi+32]
	add r8,8
	add r8,[rsi+16]			; move to next "working value"
	mov [rsi+32],r8
	add rcx,8				; move to next stack location
	mov rsi,[rsi]
	test rsi,rsi
	jnz .loop_set_inputs

; call function of interest
	call r14

; grab output parameters off stack and store them
	xor rcx,rcx
	mov rdi,r12

.loop_set_outputs:
	mov r8,[rsp+rcx]	; "pop" value at current element address of current parameter
	mov r9,[rdi+32]
	mov [r9],r8 ; take value from r8 and put into working element address
	mov r8,[rdi+32]
	add r8,8
	add r8,[rdi+16]			; move to next "working value"
	mov [rdi+32],r8
	add rcx,8				; move to next stack location
	mov rdi,[rdi]
	test rdi,rdi
	jnz .loop_set_outputs

; loop until we have exhausted all inputs
	mov rsi,[r13+24]	; number of elements in rsi
	shl rsi,3			; convert to bytes
	add rsi,[r13+8]		; add to start address
	cmp rsi,[r13+32]	; compare element beyond last element to current element

	jg .function_call_loop	; fall out when out of elements	

; reduce stack space after we have finished
	add rsp,r15

	pop r15
	pop r14
	pop r13
	pop r12
	pop rcx
	pop rdx
	pop rsi
	pop rdi

; who needs errors anyway
	xor rax,rax
	ret

%endif	
