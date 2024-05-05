%ifndef SHUNTING_YARD
%define SHUNTING_YARD

; need function to return numeric / aphabetic tokens; maybe embed that here?

shunting_yard:
; void* {rax} shunting_yard(char* {rdi});
; Parses the mathematic expression in infix notation starting at {rdi}
; into postfix notation, returned as as a linked-list structure in {rax}.
; Returns NULL {rax} on parse error.

%if 0
.integer:
	db 0b00000001 ; type 1 ; TODO, maybe remove integers completely?
	dq 0 ; next
	dq 0 ; value
.float:
	db 0b00000010 ; type 2
	dq 0 ; next
	dq 0.0 ; value
.power:
	dq 0b00000011 ; type 3
	dq 0 ; next
	db 94 ; ASCII value
	db 4 ; precedence
	db 1 ; right associativity
.multiplication:
	dq 0b00000100 ; type 4
	dq 0 ; next
	db 42 ; ASCII value
	db 3 ; precedence
	db 0 ; right associativity
.division:
	dq 0b00000101 ; type 5
	dq 0 ; next
	db 47 ; ASCII value
	db 3 ; precedence
	db 0 ; right associativity
.addition:
	dq 0b00000110 ; type 6
	dq 0 ; next
	db 43 ; ASCII value
	db 2 ; precedence
	db 0 ; right associativity
.subtraction:
	dq 0b00000111 ; type 7
	dq 0 ; next
	db 45 ; ASCII value
	db 2 ; precedence
	db 0 ; right associativity
		
%endif

%endif	
