%ifndef PRINT_FIXED
%define PRINT_FIXED

; dependency
%include "lib/io/print_chars.asm"
%include "lib/io/print_int_d.asm"

print_fixed:
; void print_fixed(int {rdi}, int {rsi}, int {rdx});
; 	Prints fixed-point value in {rsi} to file descriptor {rdi}
;	with the low {rdx} bits representing the fraction.

	push rax
	push rbx
	push rcx
	push rdx
	push rsi
	push rbp
	push r8
	push r9

	mov rbp,rsp	; save initial stack pointer

;	determine number of non-leading zero digits of {rsi} in {rcx}
	xor rcx,rcx
	mov r8,rsi
.count_digit_loop_1:
	test r8,r8
	jz .done_counting_1
	inc rcx
	shr r8,1
	jmp .count_digit_loop_1
.done_counting_1:

;	determine number of trailing zero digits of {rsi} in {rbx}
	xor rbx,rbx
	mov r8,rsi
.count_digit_loop_2:
	test r8,1
	jnz .done_counting_2
	inc rbx
	shr r8,1
	jmp .count_digit_loop_2
.done_counting_2:

;	check if number is 	BIG: 	UVWXYZ000.000
;				eg:	{rdx}=3
;					{rcx}=12
;					{rbx}=6
;					Determined if {rbx}>={rdx}.
;					Print a decimal point,
;					then ({rbx}-{rdx}) zeros,
;					then {rcx}-{rbx} nonzero digits.
;			 	MEDIUM:	000UVW.XYZ000
;				eg:	{rdx}=6
;					{rcx}=9
;					{rbx}=3
;					Determined if {rbx}<{rdx}<{rcx}.
;					Shift the number right by {rbx}.
;					Print {rdx}-{rbx} nonzero digits,
;					then a decimal point,
;					then {rcx}-{rdx} nonzero digits.
;			 	SMALL:	000.000UVWXYZ
;				eg:	{rdx}=9
;					{rcx}=6
;					{rbx}=0
;					Determined if {rcx}<={rdx}.
;					Print {rcx} nonzero digits,
;					then {rdx}-{rcx} zeros,
;					then a decimal point and a zero.

	mov r8,rsi	; save original number in {r8}
	test rsi,rsi
	js .positive
	neg rsi		; {rsi} positive only
.positive:

	mov rax,rsi	; track current number in {rax}
	mov rsi,10	; divisor for decimal system

	mov rcx,rbx
	shr rsi,cl	; shift out zeros (clobbered {rcx} here)

	cmp rdx,rcx
	jge .big
	cmp rdx,rbx
	jle .small

.medium:
	mov r9,rdx
	sub r9,rbx

.medium_loop:
	xor rdx,rdx	; zero out {rdx} before division
	div rsi		; divides full value in {rax} by 10
			; remainder in {rdx} ; dl = 0-9
			; result in {rax} for next time

	add dl,48	; {dl} now correctly contains ascii "0"-"9"

	dec rsp
	mov [rsp],dl	; move this ascii value into next slot on stack

	dec r9
	jnz .medium_not_decimal
	dec rsp
	mov [rsp], byte 46	; move "." into next slot on stack
.medium_not_decimal:
	test rax,rax	; loop until nothing nonzero left
	jnz .medium_loop

	jmp .write

.big:
	
	mov r9,rbx
	sub r9,rdx

	mov rbp,rsp
	dec rsp
	mov [rsp], byte 46	; move "." into next slot on stack
	
.big_zeros:
	dec rsp
	mov [rsp], byte 48	; move "0" into next slot on stack
	dec r9
	jnz .big_zeros

.big_loop:
	xor rdx,rdx	; zero out {rdx} before division
	div rsi		; divides full value in {rax} by 10
			; remainder in {rdx} ; dl = 0-9
			; result in {rax} for next time

	add dl,48	; {dl} now correctly contains ascii "0"-"9"

	dec rsp
	mov [rsp],dl	; move this ascii value into next slot on stack

	test rax,rax	; loop until nothing nonzero left
	jnz .big_loop

	jmp .write

.small:
	mov r9,rdx
	sub r9,rbx	

.small_loop:
	xor rdx,rdx	; zero out {rdx} before division
	div rsi		; divides full value in {rax} by 10
			; remainder in {rdx} ; dl = 0-9
			; result in {rax} for next time

	add dl,48	; {dl} now correctly contains ascii "0"-"9"

	dec rsp
	mov [rsp],dl	; move this ascii value into next slot on stack

	test rax,rax	; loop until nothing nonzero left
	jnz .small_loop

.small_zeros:
	dec rsp
	mov [rsp], byte 48	; move "0" into next slot on stack
	dec r9
	jnz .small_zeros

	dec rsp
	mov [rsp], byte 46	; move "." into next slot on stack
	dec rsp
	mov [rsp], byte 48	; move "0" into next slot on stack

.write:
	test r8,r8
	jns .no_neg_sign
	dec rsp
	mov [rsp],byte 45	; add leading negative sign if necessary

.no_neg_sign:
	
	mov rdx,rbp	
	sub rdx,rsp	; {rdx} will be length of number in bytes

	mov rsi,rsp	; address of top of red zone

	call print_chars	; print out bytes

	mov rsp,rbp	; restore stack pointer

	pop r9
	pop r8
	pop rbp
	pop rsi
	pop rdx
	pop rcx
	pop rbx
	pop rax

	ret		; return

%endif
