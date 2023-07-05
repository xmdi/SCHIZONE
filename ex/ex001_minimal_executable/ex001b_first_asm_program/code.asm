global _start		; exposes a locally defined _start function 
			; to the entire program

section .text		; section of binary dedicated for instructions

_start:			; address label representing the entry point 
			; for our program

	jmp _start	; jump to label above (execute this instruction
			; again, looping forever)
