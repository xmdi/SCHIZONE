.IFNDEF LOG_BINARY
.EQU LOG_BINARY,1

.INCLUDE "IO/LOG_TEXT.S"

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.MACRO _LOG_BINARY NUMBER // CAN ALSO PUT REGISTER
	SUB SP,SP,80
	STP LR,X0,[SP,0]
	STP X1,X2,[SP,16]
	STP X3,X4,[SP,32]
	STP X5,X6,[SP,48]
	STP X7,X8,[SP,64]
	
	MOV X0,\NUMBER
	BL LOG_BINARY

	LDP LR,X0,[SP,0]
	LDP X1,X2,[SP,16]
	LDP X3,X4,[SP,32]
	LDP X5,X6,[SP,48]
	LDP X7,X8,[SP,64]
	ADD SP,SP,80
.ENDM

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

.ALIGN 2

LOG_BINARY:// {W0} LOG_BINARY({X0});
	// RETURNS NUMBER BYTES WRITTEN IN {W0}

	MOV W4,0 // DIGIT COUNTER
	MOV X6,(4f+32) // BUFFER END
	ADD X6,X6,LOAD_ADDRESS

	CMP X0,0
	B.EQ 3f

1: 

	CMP X0,0		// CHECK IF DONE
	B.EQ 2f

	AND X2,X0,0X1
	ADD X2,X2,48

	SUB X6,X6,1		// MOVE POINTER TO PRECEDING BYTE
	STRB W2,[X6,0]		// PUSH BYTE TO BUFFER
	ADD W4,W4,1		// INCREMENT DIGIT COUNTER

	LSR X0,X0,1

	B 1b			// GO AGAIN

2: // LOOP BREAKOUT

	SUB X6,X6,LOAD_ADDRESS
	_LOG_TEXT X6 W4
	
	RET

3: // HANDLE ZERO

	SUB X6,X6,1		// MOVE POINTER TO PRECEDING BYTE
	MOV W3,48		// ASCII ZERO
	STRB W3,[X6,0]		// PUSH BYTE TO BUFFER
	MOV W4,1
	B 2b

4: // BUFFER

	.SPACE 32

.ENDIF
